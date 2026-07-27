# AI Swarm Support Stack — how the pieces work together

This package is not "every HappyMonkey repo". It is the **support plane** for the workflow:

> Top model plans → bootstrap a task board → fan out CLI agents → they claim work until done.

That matches the public HappyMonkey notes: driver model, plan first, MCP for coordination, Hermes (or similar) can drive the swarm.

## What "works together" means

| Layer | Component | Job in the swarm |
|-------|-----------|------------------|
| **Ground truth (files)** | `ai-agent-teamwork-prompt` | Task board, locks, bootstrap prompts, CLI profile YAML |
| **Protocol** | `AgentsProtocol` | How agents behave (AGENTS.md, LTM, pre-mortem, ratchet) |
| **MCP over the board** | `agent-coordination-mcp` | Driver sees CLIs, assignments, project board state |
| **MCP across agents/hosts** | `AgentCommunicationMCP` | A2A-ish tasks, provider readiness, control center |
| **Where is the work?** | `launcher-project-registry` | Paths, ports, tech stack, CONTEXT.md |
| **Can we afford more agents?** | `Resource-Sentinel-MCP` | Telemetry + leases before heavy spawn |
| **Who is the operator?** | `UserContextMCPServer` | Stack/repos/prefs for subagent bootstrap |
| **Tool budget** | `DynamicMCPProxy` | One IDE entry; lazy-mount the MCPs above |

None of these replace your coding CLIs (codex, agy, opencode, grok, hermes, …). They **coordinate** them.

## Runtime picture

```text
                    ┌─────────────────────────┐
   Driver (Hermes / │  plan + fan-out         │
   top model)       │  "use the swarm"        │
                    └───────────┬─────────────┘
                                │
              ┌─────────────────┼─────────────────┐
              ▼                 ▼                 ▼
     Agent Communication   Coordination MCP   Resource Sentinel
     (ready? mailbox?)     (board/assign)     (lease slot?)
              │                 │
              ▼                 ▼
     launcher registry    teamwork files on disk
     (which project?)     tasks.py / locks / AGENTS.md
                                │
                    ┌───────────┴───────────┐
                    ▼                       ▼
              CLI worker A            CLI worker B
              (claim task)            (claim task)

   IDE tool surface ──► DynamicMCPProxy ──► lazy activate MCPs above
   Subagent bootstrap ──► User Context + teamwork agent bootstrap prompt
```

## Standard swarm session (operator)

1. Install profile `swarm` (default).
2. `source $HM_ROOT/GENERATED/env.example`  
   (`AGENT_CLI_PROFILES_DIR`, `LAUNCHER_REGISTRY_PATH`, …).
3. Point Hermes/IDE at **DynamicMCPProxy** *or* register swarm MCPs directly.
4. On a target project, run teamwork **project bootstrap** (from `ai-agent-teamwork-prompt`).
5. Driver builds the plan/task board (optionally with `research` profile tools).
6. Before spawning many workers: **Resource Sentinel** lease / snapshot.
7. Fan out CLI agents with **agent bootstrap**; each claims one task + locks files.
8. Driver watches **Agent Communication** control center + coordination assignments.
9. Final review prompt when the board is green.

## Env contracts (shared)

| Variable | Owner | Consumers |
|----------|--------|-----------|
| `AGENT_CLI_PROFILES_DIR` | teamwork `profiles/` | Agent Communication (`suggest_cli_for_task`, readiness) |
| `LAUNCHER_REGISTRY_PATH` | launcher `registry.json` | Agent Communication, launcher MCP |
| `USER_CONTEXT_ROOT` | user-context `context/` | User Context MCP, delegation bootstrap |

Generated `env.example` sets these to the install root.

## What is intentionally out of default swarm

| Repo / idea | Why not default |
|-------------|-----------------|
| **Keymaster** | Secrets plane still maturing → profile `incubating` only |
| **Vibes** | Separate agent *runtime*/TUI still in flux — not swarm glue |
| Product apps (parent-portal, games, …) | Not coordination infrastructure |
| Research/data MCPs | Driver helpers; use `research` / `data` overlays |
| AuditScan / repo-security-scan | Strong future *gates* in the loop; not required to form a swarm |

## Maturity honesty

- Teamwork is explicitly early/beta coordination — files + locks, not a heavy orchestrator.
- agent-coordination-mcp is a thin MCP face on that workflow (assignments first; deep CLI process supervision later).
- Agent Communication is the richer cross-agent/control-center surface.
- The stack is **composable infrastructure**, not one binary that "runs the swarm for you".

## Profile cheat sheet

```bash
./install.sh --profile swarm          # default — support plane only
./install.sh --profile research       # + planning research MCPs
./install.sh --profile data           # + UK/US public data
./install.sh --profile full           # swarm + research + data + light ops
./install.sh --profile incubating     # Keymaster clone only
```

`core` remains an alias of `swarm`.
