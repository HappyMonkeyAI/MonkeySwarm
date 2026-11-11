# DevHost offload allowlist (desktop ∩ launcher)

**Status:** operational note (not a mass-repo rollout)  
**Date:** 2026-10-29  
**Sources:** `/var/www/html/launcher/registry.json` on `192.168.5.215` (19 projects) ∩ `C:\Users\steph\Documents\development` + `C:\Users\steph\happymonkey`  
**Related:** `2026-10-28-devhost-capability-card.md`, Cursor rule `devhost-resource-offload.mdc`, agent card `host-dev-215`

## Decision

Do **not** stamp offload docs into every local project. Keep placement global (Cursor rule + Sentinel MCP + Agent Communication). Use this allowlist when an agent asks “can this heavy job run on DevHost?”

## How to use

1. `recommend_execution_host` (desktop Sentinel; peers → `http://192.168.5.215:8800`).
2. If `peer` / `dev-215`: `get_agent_card(host-dev-215)` → admit lease on the **peer** Sentinel → `submit_task` with `approval_required` + `sentinel_lease_id` against a **DevHost** project slug.
3. Worker + Hermes must see the DevHost Agent Communication DB / profiles (`AGENT_CLI_PROFILES_DIR=/home/stephen/projects/ai-agent-teamwork/profiles`). Desktop MCP SQLite ≠ DevHost worker DB.
4. Prefer Hermes `--provider openai-codex` until `~/.hermes/config.yaml` custom base (`192.168.5.157:8888`) is healthy again.

## Tier A — registry ∩ local twin (offload-ready)

Unique local roots that appear in the live DevHost launcher registry. Prefer the **canonical slug** when submitting tasks.

| Local root | Prefer slug | Remote path | Heavy? | Notes |
|---|---|---|---|---|
| `Documents\development\EchoesOfAion` | `echoes-of-aion-e2e-task12` | `/home/stephen/projects/EchoesOfAion` | yes | Also has map-QA slugs; same tree |
| `Documents\development\MRPGRealms` | `mrpg-realms` | `/home/stephen/projects/MRPGRealms` | yes | Three.js / multiplayer |
| `Documents\development\AshfallRTS` | `ashfall-rts` | `/home/stephen/projects/AshfallRTS` | med (docs/scan) | UE research clone; LFS skipped on DevHost — no Linux Editor. Hermes: docs/AuditScan/crosswalk only |
| `Documents\development\Random-Realm` | `random-realm` | `/home/stephen/projects/Random-Realm` | heavy (docs/scan) | Unity NGO collab; LFS skipped on DevHost — no Linux Editor. Hermes/SSH: AuditScan, docs, source analysis only |
| `Documents\development\restaurantMarketingAgent` | `restaurant-marketing-agent-naz-preview` | `/home/stephen/projects/restaurantMarketingAgent` | low–med | Preview slugs; pick matching preview |
| `happymonkey\article-research-mcp` | `article-research-mcp` | `/home/stephen/projects/article-research-mcp` | low | MCP tests/uv |
| `Documents\development\kev-decision-mcp` | `kev-decision-mcp` | `/home/stephen/projects/jev_mcp` | low | Slug name ≠ remote folder (`jev_mcp`) |
| `Documents\development\social_trading` | `social-trading` | `/home/stephen/projects/social_trading` | med | Registered 2026-11-09; Jules + Vite feed PoC |
| `Documents\development\construct` | `construct` | `/home/stephen/projects/construct` | med | Registered 2026-11-11; WebXR kitbash; sync via `scripts/devhost-sync.ps1` |

## Tier B — DevHost registry only (no Windows twin)

Offload by creating/running work **on DevHost** with these slugs; do not invent a desktop path.

| Slug | Remote path | Notes |
|---|---|---|
| `chip` | `/home/stephen/projects/chip` | Used in Hermes smoke |
| `browseros-neo-bridge` | `/home/stephen/projects/browserosNeoBridge` | Host service |
| `devto-mcp-server` | `/home/stephen/projects/devto-mcp-server` | |
| `flipbookagent` | `/home/stephen/projects/booganim` | Comfy/LM Studio — DevHost-shaped |
| `ai-marketplace` | `/home/stephen/projects/ai-marketplace` | |
| `ag-voice-log` | `/home/stephen/projects/ag-voice-log` | |
| `xfeed` | `/home/stephen/projects/xfeed` | |
| `webshare` | `/home/stephen/projects/webshare` | |
| `restaurant-table-manager` | `/home/stephen/projects/restaurant-table-manager` | |
| `herding-cats-multiplayer` | `/home/stephen/projects/herdingcats/server` | |
| `echoes-aion-mapqa-20261002` | `/tmp/...` | completed disposable |
| `restaurant-marketing-agent-three-demo-review-20261007` | _(none)_ | inactive record |

## Tier C — heavy local, **not** in DevHost registry

Do **not** claim offload via launcher slug until the project is cloned/registered on `.215`. Sentinel may still say `peer` for machine pressure — that means “run a registered DevHost workload,” not “magic-sync this Windows folder.”

| Local root | Why it matters |
|---|---|
| `Documents\development\vibes-desktop` | Heavy desktop UI |
| `Documents\development\ThreeGameForge` | 3D / pipeline |
| `Documents\development\xeno-gate-tactical` | Game / build |
| `happymonkey\agent-communication-mcp` | Infra — prefer local + DevHost clone already at `~/projects/agent-communication-mcp` |
| `Documents\development\Resource-Sentinel-MCP` (+ happymonkey copy) | Infra — desktop admits locally; peer Sentinel is already on `.215` |
| `Documents\development\MonkeySwarm` | Docs/orchestration, not a launcher project |

## Explicit non-goals

- Copying `devhost-resource-offload` into every `AGENTS.md` under `Documents\development`.
- Treating desktop `list_projects` (sparse Windows registry) as SoT — DevHost `/var/www/html/launcher` is SoT for remote slugs.
- Transferring Sentinel leases across hosts.

## Refresh

Re-run intersection when launcher registry changes:

1. `scp`/ssh cat `/var/www/html/launcher/registry.json`
2. Match remote basename / slug to folder names under `development` + `happymonkey`
3. Update Tier A/B tables; leave Tier C as aspirational register-candidates
