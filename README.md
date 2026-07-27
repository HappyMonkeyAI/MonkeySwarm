# HappyMonkey Dev Ecosystem

One-command install for the HappyMonkeyAI **agent development plane**: MCP servers, swarm prompts, and wiring so a top model can plan and fan work out to CLI coding agents.

This is a **meta-package** (catalogue + installer), not a monorepo of all source. Each tool stays in its own GitHub repo under [HappyMonkeyAI](https://github.com/HappyMonkeyAI). The installer clones the ones you want, installs deps, and generates Hermes / DynamicMCPProxy / generic MCP client config.

## Why

Public workflow notes from [@HappyMonkeyAI](https://x.com/HappyMonkeyAI):

1. Run a top model as **driver** — analyse, plan, pick models per task.
2. **Plan first**, then fan out to sub-agents / CLI tools.
3. Use MCP for **agent coordination**, resource awareness, project registry, and lazy tool loading.
4. Bootstrap a task board; each CLI agent claims work until the plan is done.
5. Hermes (or similar) can drive the swarm.

Those pieces already exist as separate repos. This package makes them a single installable ecosystem.

## Profiles

| Profile | What you get |
|---------|----------------|
| `core` (default) | DynamicMCPProxy, launcher registry, Agent Communication, Resource Sentinel, User Context, ai-agent-teamwork prompts, agent-coordination MCP |
| `research` | core + article-research, social-research, devto |
| `data` | core + OpenUK / OpenUS public data MCPs |
| `full` | everything in `components.yaml` |

## Quick install

Prereqs: `git`, `python3`, and [`uv`](https://github.com/astral-sh/uv) (for FastMCP Python servers).

```bash
git clone https://github.com/HappyMonkeyAI/happymonkey-dev-ecosystem.git
cd happymonkey-dev-ecosystem
chmod +x install.sh
./install.sh --profile core --dir "$HOME/happymonkey"
```

Or inspect first, then run:

```bash
./install.sh --help
./install.sh --dry-run --profile research
./install.sh --profile research --hermes
```

Optional non-interactive Hermes registration (when `hermes` is on PATH):

```bash
./install.sh --profile core --register-hermes
```

## After install

```text
~/happymonkey/
  DynamicMCPProxy/
  launcher-project-registry/
  agent-communication-mcp/
  Resource-Sentinel-MCP/
  ...
  bin/hm-*                  # stdio wrappers
  GENERATED/
    README.md
    hermes-mcp.snippet.yaml
    hermes-register.sh
    user.catalogue.fragment.json
    mcp.json
    env.example
```

```bash
source ~/happymonkey/GENERATED/env.example
export PATH="$HOME/happymonkey/bin:$PATH"
```

### Recommended IDE wiring

Point the IDE at **DynamicMCPProxy only**, then merge `GENERATED/user.catalogue.fragment.json` into the proxy user catalogue so tools activate lazily (IDE tool-budget friendly).

### Hermes

Merge `GENERATED/hermes-mcp.snippet.yaml` into MCP config, or run `GENERATED/hermes-register.sh`.

## Component map (core)

| Component | Role |
|-----------|------|
| [DynamicMCPProxy](https://github.com/HappyMonkeyAI/DynamicMCPProxy) | Lazy MCP gateway / rotating tool belt |
| [launcher-project-registry](https://github.com/HappyMonkeyAI/launcher-project-registry) | Projects, ports, paths, CONTEXT for agents |
| [AgentCommunicationMCP](https://github.com/HappyMonkeyAI/AgentCommunicationMCP) | A2A-shaped tasks, provider readiness, control center |
| [Resource-Sentinel-MCP](https://github.com/HappyMonkeyAI/Resource-Sentinel-MCP) | Host telemetry + lease admission for heavy jobs |
| [UserContextMCPServer](https://github.com/HappyMonkeyAI/UserContextMCPServer) | Local stack/repos/communication context |
| [ai-agent-teamwork-prompt](https://github.com/HappyMonkeyAI/ai-agent-teamwork-prompt) | Swarm templates + CLI profile YAML |
| [agent-coordination-mcp](https://github.com/HappyMonkeyAI/agent-coordination-mcp) | Task-board / lock control plane |

Research/data/optional ids are listed in [`components.yaml`](./components.yaml).

## Layout of this repo

```text
components.yaml          # human source of truth
components.json          # install-time catalogue (no PyYAML required)
install.sh               # hardened installer
scripts/                 # profile resolve + artifact generation
templates/               # extra client snippets (optional copies)
docs/ARCHITECTURE.md     # design notes
```

## Design choices

- **Meta-repo, not monorepo** — independent versioning and licenses stay on each tool; ecosystem repo only orchestrates.
- **Profiles** — core swarm plane vs research vs data vs full.
- **Generated wiring only under `$ROOT/GENERATED`** — never overwrite your live Hermes `config.yaml` without `--register-hermes`.
- **No secrets in git** — env template only; credentials stay local.
- **Mirrors** — DynamicMCPProxy can fall back to known fork URLs if the primary clone fails.

## Development

```bash
# refresh json after editing yaml (needs PyYAML)
./install.sh --json --generate-only --dir /tmp/hm-test --dry-run

python3 -m compileall scripts
PROFILE=core ONLY= CATALOGUE_JSON=./components.json python3 scripts/resolve_profile.py
```

## Status

Scaffold for public packaging of the existing HappyMonkeyAI MCP plane. Installer and catalogue are the product of this repo; individual servers continue to live upstream.

## License

MIT — see [LICENSE](./LICENSE). Individual components keep their own licenses.
