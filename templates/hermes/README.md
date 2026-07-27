# MCP client template notes

After `./install.sh`, prefer the generated files under `$HM_ROOT/GENERATED/`:

- `hermes-mcp.snippet.yaml` — paste under Hermes `mcp_servers`
- `mcp.json` — Claude Desktop / many stdio MCP clients
- `user.catalogue.fragment.json` — merge into DynamicMCPProxy user catalogue
- `hermes-register.sh` — non-interactive `hermes mcp add` batch

Do not commit machine-specific generated paths to this repo.
