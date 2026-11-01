# AGENTS.md — MonkeySwarm

Meta-package for the HappyMonkeyAI **swarm support plane** (catalogue + installer). Component repos stay separate under HappyMonkeyAI.

## Session start and end (Spine)
If the `spine` MCP is available, call `session_brief(project="monkey-swarm")` (or the absolute path of this repo) first and use `get_section` / `recall` instead of reading PROGRESS.md or CONTEXT.md whole. Without the MCP, run `spine brief` from the repo root. If neither works, ground normally.
Before you stop, call `checkpoint` with your agent name (e.g. `hermes`), what was done, what's next and any blockers. Save durable why/gotcha/decision facts with `record_memory`.

## Orient
1. Read `README.md` and `docs/SWARM.md`
2. Prefer existing checkouts on this host over reinstalling:
   - spine-mcp, Resource-Sentinel-MCP, DynamicMCPProxy (`~/dynamic-mcp-proxy-server`), launcher registry, AgentsProtocol
3. Profiles: `swarm` (default), `research`, `data`, `full`, `incubating`
4. Do not treat this repo as a monorepo of product code

## Commands
```bash
./install.sh --help
./install.sh --dry-run --profile swarm
# optional: ./install.sh --profile swarm --dir "$HOME/happymonkey"
```
