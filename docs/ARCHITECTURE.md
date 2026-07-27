# Architecture — HappyMonkey Dev Ecosystem

## Problem

HappyMonkeyAI ships many complementary MCP servers and prompt packs:

- coordination (Agent Communication, agent-coordination, teamwork profiles)
- host awareness (Resource Sentinel)
- project memory (launcher registry, user context)
- tool budget (DynamicMCPProxy)
- research / public data (article, social, OpenUK, …)

Each is a separate repo with its own install story. Assembling a working **development plane** by hand is slow and easy to mis-wire.

## Approach

A **meta-package**:

1. Declarative catalogue (`components.yaml` → `components.json`)
2. Profile expansion (`core` / `research` / `data` / `full`)
3. `install.sh` clones or updates checkouts under `$HM_ROOT` (default `~/happymonkey`)
4. Per-kind dependency sync (`uv sync` or venv+pip)
5. Artifact generation (wrappers, Hermes snippet, proxy catalogue fragment, `mcp.json`)

This is intentionally **not** a git-submodule monorepo of all source. Upstream repos remain canonical for code review, CI, and releases.

## Runtime shapes

```text
                    ┌──────────────────────┐
   IDE / Hermes ───►│  DynamicMCPProxy     │  optional single entry
                    │  (lazy activate)     │
                    └─────────┬────────────┘
                              │ mounts
        ┌────────────┬────────┼────────┬────────────┐
        ▼            ▼        ▼        ▼            ▼
   launcher     agent_comm  sentinel  research    data MCPs
   registry     + profiles
```

Driver workflow:

```text
Top model (plan) → task board bootstrap → CLI agents claim tasks
                 ↘ Agent Communication / Resource Sentinel
```

## Install trust model

- Prefer clone-then-run `install.sh` from a reviewed checkout.
- `install.sh` refuses to clobber unrelated directories.
- `--register-hermes` is opt-in; default only writes `GENERATED/` snippets.
- No API keys are written by the installer.

## Extension

Add a component:

1. Entry under `components:` in `components.yaml`
2. Attach id to one or more `profiles`
3. `./install.sh --json` to refresh `components.json`
4. `./install.sh --only <id> --dir ...`

## Non-goals

- Replacing each project's own README / CI
- Shipping Keymaster PHP stack as a fully automated service
- Remote SSH wrapper generation for multi-machine Hermes (host-specific; keep local)
