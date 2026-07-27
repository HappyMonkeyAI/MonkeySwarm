# HappyMonkey AI Swarm Support Stack

One-command install for the HappyMonkeyAI **swarm support plane**: the MCP servers + prompt packs that let a top model **plan** and **fan work out** to CLI coding agents on a shared task board.

This is a **meta-package** (catalogue + installer), not a monorepo of every HappyMonkey product. Each component stays in its own repo under [HappyMonkeyAI](https://github.com/HappyMonkeyAI).

## Intent

Not "install all my GitHub toys". The product is a **coherent AI swarm support stack**:

1. Driver model analyses and plans.
2. Teamwork bootstrap creates task board + locks + `AGENTS.md`.
3. Coordination / communication MCPs let the driver see readiness and assignments.
4. Resource Sentinel gates heavy fan-out on a shared host.
5. Launcher registry + user context stop agents guessing paths and prefs.
6. DynamicMCPProxy keeps the IDE tool list under budget while the plane stays available.
7. CLI workers (codex, agy, opencode, grok, hermes, …) claim tasks until the board is done.

How the pieces wire: **[docs/SWARM.md](./docs/SWARM.md)**.

## Profiles

| Profile | What you get |
|---------|----------------|
| **`swarm` (default)** | Teamwork prompts, Agents Protocol, agent-coordination MCP, Agent Communication, launcher registry, Resource Sentinel, User Context, DynamicMCPProxy |
| `core` | Alias of `swarm` |
| `research` | swarm + article / social / devto research MCPs (driver planning) |
| `data` | swarm + OpenUK / OpenUS public-data MCPs |
| `full` | swarm + research + data + light ops helpers |
| `incubating` | In-dev only (e.g. Keymaster) — **not** part of the stable plane |

Vibes and other unfinished runtimes are **out of tree** until they are stable swarm deps.

## Quick install

Prereqs: `git`, `python3`, [`uv`](https://github.com/astral-sh/uv).

```bash
git clone https://github.com/HappyMonkeyAI/happymonkey-dev-ecosystem.git
cd happymonkey-dev-ecosystem
chmod +x install.sh
./install.sh --profile swarm --dir "$HOME/happymonkey"
```

```bash
./install.sh --help
./install.sh --dry-run --profile swarm
./install.sh --profile research --hermes
# optional: ./install.sh --register-hermes
```

## After install

```text
~/happymonkey/
  ai-agent-teamwork-prompt/
  AgentsProtocol/
  agent-coordination-mcp/
  agent-communication-mcp/
  launcher-project-registry/
  Resource-Sentinel-MCP/
  user-context-mcp/
  DynamicMCPProxy/
  bin/hm-*
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

### IDE / Hermes

- Prefer **DynamicMCPProxy** as the single MCP entry; merge `GENERATED/user.catalogue.fragment.json` into the proxy user catalogue.
- Or merge `GENERATED/hermes-mcp.snippet.yaml` / run `hermes-register.sh`.

### First swarm on a project

1. Source `env.example` (profiles + registry paths).
2. From `ai-agent-teamwork-prompt`, run **project bootstrap** on the target repo.
3. Driver fills the task board (optionally with `--profile research` tools).
4. Check Resource Sentinel before large fan-out.
5. Start CLI workers with the **agent bootstrap** prompt; each claims one task.
6. Driver monitors Agent Communication + coordination MCP until done; run final review.

## Swarm component map

| Component | Role |
|-----------|------|
| [ai-agent-teamwork-prompt](https://github.com/HappyMonkeyAI/ai-agent-teamwork-prompt) | Task board, locks, bootstrap, CLI profiles |
| [AgentsProtocol](https://github.com/HappyMonkeyAI/AgentsProtocol) | Agent operating protocol / LTM patterns |
| [agent-coordination-mcp](https://github.com/HappyMonkeyAI/agent-coordination-mcp) | MCP face on the file-based board |
| [AgentCommunicationMCP](https://github.com/HappyMonkeyAI/AgentCommunicationMCP) | Readiness, mailbox, control center |
| [launcher-project-registry](https://github.com/HappyMonkeyAI/launcher-project-registry) | Projects, ports, CONTEXT |
| [Resource-Sentinel-MCP](https://github.com/HappyMonkeyAI/Resource-Sentinel-MCP) | Host load + execution leases |
| [UserContextMCPServer](https://github.com/HappyMonkeyAI/UserContextMCPServer) | Operator context for workers |
| [DynamicMCPProxy](https://github.com/HappyMonkeyAI/DynamicMCPProxy) | Lazy tool gateway |

Overlays and incubating tools stay in [`components.yaml`](./components.yaml).

## Design choices

- **Meta-repo, not monorepo** — upstream repos remain canonical.
- **Swarm-first default** — research/data/ops are overlays.
- **Incubating is explicit** — unfinished secrets/runtime work is not sold as swarm glue.
- **Generated wiring only under `$ROOT/GENERATED`** — live Hermes config only with `--register-hermes`.
- **No secrets in git**.

## Development

```bash
./install.sh --json --dry-run --profile swarm
python3 -m compileall scripts
PROFILE=swarm ONLY= CATALOGUE_JSON=./components.json python3 scripts/resolve_profile.py
```

## License

MIT — see [LICENSE](./LICENSE). Components keep their own licenses.
