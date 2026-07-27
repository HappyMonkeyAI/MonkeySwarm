#!/usr/bin/env bash
# HappyMonkey Dev Ecosystem installer
# Meta-package: clones selected HappyMonkeyAI MCP/tools and wires local configs.
set -euo pipefail

PROJECT_NAME="happymonkey-dev-ecosystem"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CATALOGUE_JSON="${SCRIPT_DIR}/components.json"
CATALOGUE_YAML="${SCRIPT_DIR}/components.yaml"

log()  { printf '[%s] %s\n' "${PROJECT_NAME}" "$*" >&2; }
warn() { printf '[%s] WARN: %s\n' "${PROJECT_NAME}" "$*" >&2; }
fail() { printf '[%s] ERROR: %s\n' "${PROJECT_NAME}" "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command '$1' is not installed or not on PATH."
}

usage() {
  cat <<USAGE
Install the HappyMonkey development ecosystem (MCP servers + swarm prompts).

Usage:
  ./install.sh [options]

Options:
  --dir PATH           Root install directory (default: ~/happymonkey)
  --profile NAME       core | research | data | full (default: core)
  --only LIST          Comma-separated component ids (overrides profile)
  --no-sync            Clone/update only; skip dependency installs
  --skip-existing      Do not git pull existing checkouts
  --hermes             Print + optionally register Hermes MCP entries when hermes CLI exists
  --register-hermes    Non-interactive hermes mcp add for supported components
  --generate-only      Only regenerate configs/wrappers from already-installed tree
  --dry-run            Show planned actions without changing the system
  --json               Refresh components.json from components.yaml before install
  -h, --help           Show this help

Examples:
  curl -fsSL https://raw.githubusercontent.com/HappyMonkeyAI/happymonkey-dev-ecosystem/main/install.sh -o install.sh
  chmod +x install.sh && ./install.sh --profile core

  ./install.sh --dir "\$HOME/happymonkey" --profile research --hermes
  ./install.sh --only dynamic-mcp-proxy,resource-sentinel-mcp

After install, see:
  \$ROOT/GENERATED/README.md
  \$ROOT/GENERATED/hermes-mcp.snippet.yaml
  \$ROOT/GENERATED/user.catalogue.fragment.json
USAGE
}

expand_home() {
  local p="$1"
  p="${p//\$\{HOME\}/$HOME}"
  p="${p//\$HOME/$HOME}"
  printf '%s' "$p"
}

ROOT="$(expand_home "${HM_ROOT:-${HOME}/happymonkey}")"
PROFILE="core"
ONLY=""
SYNC_DEPS=1
SKIP_EXISTING=0
HERMES_HINTS=0
REGISTER_HERMES=0
GENERATE_ONLY=0
DRY_RUN=0
REFRESH_JSON=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) [[ $# -ge 2 ]] || fail "--dir requires a path"; ROOT="$(expand_home "$2")"; shift 2 ;;
    --profile) [[ $# -ge 2 ]] || fail "--profile requires a name"; PROFILE="$2"; shift 2 ;;
    --only) [[ $# -ge 2 ]] || fail "--only requires a list"; ONLY="$2"; shift 2 ;;
    --no-sync) SYNC_DEPS=0; shift ;;
    --skip-existing) SKIP_EXISTING=1; shift ;;
    --hermes) HERMES_HINTS=1; shift ;;
    --register-hermes) HERMES_HINTS=1; REGISTER_HERMES=1; shift ;;
    --generate-only) GENERATE_ONLY=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --json) REFRESH_JSON=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown argument: $1" ;;
  esac
done

need_cmd git
need_cmd python3

if [[ "$REFRESH_JSON" -eq 1 || ! -f "$CATALOGUE_JSON" ]]; then
  if [[ -f "$CATALOGUE_YAML" ]]; then
    log "Refreshing components.json from components.yaml"
    if [[ "$DRY_RUN" -eq 0 ]]; then
      python3 "${SCRIPT_DIR}/scripts/yaml_to_json.py" "$CATALOGUE_YAML" "$CATALOGUE_JSON"
    fi
  fi
fi

[[ -f "$CATALOGUE_JSON" ]] || fail "Missing catalogue: $CATALOGUE_JSON (run with --json next to components.yaml)"

# Resolve component id list via helper
mapfile -t COMPONENT_IDS < <(
  PROFILE="$PROFILE" ONLY="$ONLY" CATALOGUE_JSON="$CATALOGUE_JSON" \
    python3 "${SCRIPT_DIR}/scripts/resolve_profile.py"
)

[[ ${#COMPONENT_IDS[@]} -gt 0 ]] || fail "No components resolved for profile='${PROFILE}' only='${ONLY}'"

log "Install root: ${ROOT}"
log "Profile: ${PROFILE}${ONLY:+ (only override)}"
log "Components (${#COMPONENT_IDS[@]}): ${COMPONENT_IDS[*]}"
[[ "$DRY_RUN" -eq 1 ]] && log "DRY RUN — no filesystem changes from clone/sync"

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: $*"
    return 0
  fi
  "$@"
}

ensure_dir() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: mkdir -p $1"
    return 0
  fi
  mkdir -p "$1"
}

clone_or_update() {
  local id="$1"
  local meta
  meta="$(COMPONENT_ID="$id" CATALOGUE_JSON="$CATALOGUE_JSON" python3 "${SCRIPT_DIR}/scripts/component_meta.py")"
  local repo dir url
  repo="$(printf '%s\n' "$meta" | python3 -c 'import sys,json; print(json.load(sys.stdin)["repo"])')"
  dir="$(printf '%s\n' "$meta" | python3 -c 'import sys,json; print(json.load(sys.stdin)["dir"])')"
  url="https://github.com/${repo}.git"
  local target="${ROOT}/${dir}"
  local mirrors
  mirrors="$(printf '%s\n' "$meta" | python3 -c 'import sys,json; print("\n".join(json.load(sys.stdin).get("mirror_urls") or []))')"

  if [[ "$GENERATE_ONLY" -eq 1 ]]; then
    [[ -d "$target" ]] || warn "generate-only: missing ${target}"
    printf '%s\n' "$target"
    return 0
  fi

  if [[ -d "$target/.git" ]]; then
    if [[ "$SKIP_EXISTING" -eq 1 ]]; then
      log "Skip update: $target"
    else
      log "Updating $target"
      if [[ "$DRY_RUN" -eq 0 ]]; then
        git -C "$target" fetch --prune origin 2>/dev/null || warn "fetch failed for $id"
        local branch
        branch="$(git -C "$target" symbolic-ref --quiet --short HEAD 2>/dev/null || true)"
        if [[ -n "$branch" ]]; then
          git -C "$target" pull --ff-only origin "$branch" 2>/dev/null \
            || warn "fast-forward skipped for $id"
        fi
      else
        log "DRY: git pull $target"
      fi
    fi
  elif [[ -e "$target" ]]; then
    warn "Exists but is not a git checkout: $target (leaving in place)"
  else
    log "Cloning $url -> $target"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "DRY: git clone $url $target"
    else
      ensure_dir "$(dirname "$target")"
      if ! git clone "$url" "$target" 2>/dev/null; then
        local ok=0 m
        while IFS= read -r m; do
          [[ -z "$m" ]] && continue
          log "Clone failed; trying mirror $m"
          if git clone "$m" "$target"; then ok=1; break; fi
        done <<< "$mirrors"
        [[ "$ok" -eq 1 ]] || fail "Could not clone $repo"
      fi
    fi
  fi
  printf '%s\n' "$target"
}

sync_component() {
  local id="$1"
  local target="$2"
  [[ "$SYNC_DEPS" -eq 1 ]] || { log "Skip sync: $id"; return 0; }

  local kind
  kind="$(COMPONENT_ID="$id" CATALOGUE_JSON="$CATALOGUE_JSON" python3 - <<'PY'
import json,os
from pathlib import Path
c=json.loads(Path(os.environ["CATALOGUE_JSON"]).read_text())["components"][os.environ["COMPONENT_ID"]]
print(c.get("kind",""))
PY
)"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    case "$kind" in
      mcp_python_uv|proxy) log "DRY: uv sync → $id ($target)" ;;
      mcp_python_pip) log "DRY: venv+pip → $id ($target)" ;;
      prompts|other) log "DRY: no runtime deps → $id" ;;
      *) log "DRY: sync kind=$kind → $id" ;;
    esac
    return 0
  fi

  case "$kind" in
    mcp_python_uv|proxy)
      need_cmd uv
      if [[ -f "$target/pyproject.toml" ]]; then
        log "uv sync → $id"
        (cd "$target" && uv sync)
      else
        warn "No pyproject.toml in $target"
      fi
      ;;
    mcp_python_pip)
      need_cmd python3
      if [[ -f "$target/requirements.txt" ]]; then
        log "venv+pip → $id"
        [[ -d "$target/venv" ]] || python3 -m venv "$target/venv"
        "$target/venv/bin/pip" install --upgrade pip -q
        "$target/venv/bin/pip" install -r "$target/requirements.txt" -q
      else
        warn "No requirements.txt in $target"
      fi
      ;;
    prompts|other)
      log "No runtime deps: $id"
      ;;
    *)
      if [[ -f "$target/pyproject.toml" ]] && command -v uv >/dev/null 2>&1; then
        log "uv sync (fallback) → $id"
        (cd "$target" && uv sync)
      else
        log "No sync handler for kind=$kind ($id)"
      fi
      ;;
  esac

  # user-context example copy
  if [[ "$id" == "user-context-mcp" && -d "$target/context" ]]; then
    local f
    for f in communication memory-model repos stack; do
      if [[ -f "$target/context/${f}.md.example" && ! -f "$target/context/${f}.md" ]]; then
        log "Seeding context/${f}.md from example"
        cp "$target/context/${f}.md.example" "$target/context/${f}.md"
      fi
    done
  fi
}

write_wrapper() {
  local name="$1"
  local body="$2"
  local path="${ROOT}/bin/${name}"
  ensure_dir "${ROOT}/bin"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "DRY: write wrapper $path"
    return 0
  fi
  printf '%s\n' "$body" > "$path"
  chmod +x "$path"
  log "Wrapper: $path"
}

generate_artifacts() {
  log "Generating config artifacts under ${ROOT}/GENERATED"
  ensure_dir "${ROOT}/GENERATED"
  ensure_dir "${ROOT}/bin"

  ROOT="$ROOT" CATALOGUE_JSON="$CATALOGUE_JSON" COMPONENT_IDS="${COMPONENT_IDS[*]}" \
    SCRIPT_DIR="$SCRIPT_DIR" DRY_RUN="$DRY_RUN" \
    python3 "${SCRIPT_DIR}/scripts/generate_artifacts.py"

  # Convenience PATH note
  if [[ "$DRY_RUN" -eq 0 ]]; then
    cat > "${ROOT}/GENERATED/README.md" <<EOF
# HappyMonkey Dev Ecosystem — generated install

Root: \`${ROOT}\`
Profile: \`${PROFILE}\`
Components: ${COMPONENT_IDS[*]}

## Quick use

1. Put wrappers on PATH (optional):
   \`\`\`bash
   export PATH="${ROOT}/bin:\$PATH"
   \`\`\`

2. **DynamicMCPProxy** (recommended single IDE entry):
   - Project: \`${ROOT}/DynamicMCPProxy\`
   - Merge \`${ROOT}/GENERATED/user.catalogue.fragment.json\` into the proxy user catalogue
   - Point your IDE MCP config at the proxy only (keeps tool count low)

3. **Hermes** direct MCP register:
   - Snippet: \`${ROOT}/GENERATED/hermes-mcp.snippet.yaml\`
   - Or re-run: \`./install.sh --dir ${ROOT} --generate-only --register-hermes\`

4. **CLI swarm profiles**:
   \`\`\`bash
   export AGENT_CLI_PROFILES_DIR="${ROOT}/ai-agent-teamwork-prompt/profiles"
   export LAUNCHER_REGISTRY_PATH="${ROOT}/launcher-project-registry/registry.json"
   \`\`\`

5. Env template: \`${ROOT}/GENERATED/env.example\`

## Driver workflow (from the public HappyMonkey notes)

1. Top model analyses the repo and writes a plan + task board.
2. Bootstrap swarm prompts from \`ai-agent-teamwork-prompt\`.
3. Fan out CLI agents (codex / agy / opencode / grok / hermes) — each claims a task.
4. Use Agent Communication + Resource Sentinel so the driver stays resource-aware.
5. Keep IDE tool budget sane via DynamicMCPProxy lazy activation.

EOF
  fi
}

maybe_register_hermes() {
  [[ "$REGISTER_HERMES" -eq 1 ]] || return 0
  if ! command -v hermes >/dev/null 2>&1; then
    warn "hermes CLI not on PATH; skip --register-hermes"
    return 0
  fi
  local snippet="${ROOT}/GENERATED/hermes-register.sh"
  if [[ -f "$snippet" ]]; then
    log "Running Hermes register script: $snippet"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "DRY: bash $snippet"
    else
      bash "$snippet" || warn "Hermes registration reported errors (see above)"
    fi
  else
    warn "No hermes-register.sh generated"
  fi
}

# --- main ---
ensure_dir "$ROOT"

declare -a TARGETS=()
for id in "${COMPONENT_IDS[@]}"; do
  t="$(clone_or_update "$id")"
  TARGETS+=("$t")
  if [[ "$GENERATE_ONLY" -eq 0 ]]; then
    sync_component "$id" "$t"
  fi
done

generate_artifacts
maybe_register_hermes

if [[ "$HERMES_HINTS" -eq 1 && "$REGISTER_HERMES" -eq 0 ]]; then
  log "Hermes snippet: ${ROOT}/GENERATED/hermes-mcp.snippet.yaml"
fi

log "Done."
log "Read: ${ROOT}/GENERATED/README.md"
printf '  export PATH=%q:$PATH\n' "${ROOT}/bin"
