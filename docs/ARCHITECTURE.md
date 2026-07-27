# Architecture — AI Swarm Support Stack

## Problem

HappyMonkeyAI has many repos. Only a subset is **swarm infrastructure**:

- file-based teamwork (task board, locks, CLI profiles)
- MCP control planes over that workflow
- project registry, resource admission, operator context
- lazy MCP proxy for IDE tool budgets

Assembling those by hand is slow. Pulling *every* product app into one installer dilutes the product.

## Product boundary

**In:** coordination plane for driver → plan → CLI fan-out.  
**Out by default:** unfinished secrets/runtime work (Keymaster, Vibes), consumer apps, games.  
**Optional overlays:** research MCPs, public-data MCPs.

See [SWARM.md](./SWARM.md) for the composition diagram and session flow.

## Approach

A **meta-package**:

1. Declarative catalogue (`components.yaml` → `components.json`) with `role` / `wires_to` metadata
2. Profile expansion (`swarm` default, `research` / `data` / `full` / `incubating`)
3. `install.sh` clones or updates checkouts under `$HM_ROOT` (default `~/happymonkey`)
4. Per-kind dependency sync (`uv sync` or venv+pip)
5. Artifact generation (wrappers, Hermes snippet, proxy catalogue fragment, shared `env.example`)

Not a git-submodule monorepo. Upstream repos stay canonical.

## Shared contracts

Install-generated env must align:

- `AGENT_CLI_PROFILES_DIR` → teamwork `profiles/` (Agent Communication readiness + routing)
- `LAUNCHER_REGISTRY_PATH` → launcher `registry.json`
- `USER_CONTEXT_ROOT` → user-context markdown sections

## Install trust model

- Prefer clone-then-run `install.sh` from a reviewed checkout.
- Refuse to clobber unrelated directories.
- `--register-hermes` is opt-in; default only writes `GENERATED/`.
- No API keys written by the installer.
- `incubating` profile never merges into `swarm`/`full` by accident.

## Extension

1. Add under `components:` with `tier` + `role` + `wires_to`
2. Attach to the right profile only
3. `./install.sh --json` then dry-run

## Non-goals

- Replacing each project's README / CI
- Auto-shipping Keymaster or Vibes as stable swarm deps
- One binary that runs the entire swarm without CLI workers
- Remote SSH multi-machine wrappers (host-specific)
