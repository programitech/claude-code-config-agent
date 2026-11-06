# MCP servers, plugins, marketplaces

Verified against https://code.claude.com/docs/en/mcp.md, plugins/install.md, plugins/manifest-reference.md, plugins/marketplace-reference.md for Claude Code 2.1.284 on 2026-11-06.

## MCP

Scopes (precedence local > project > user > plugin > claude.ai connectors; the winning entry is used whole):

| Scope | Stored in | Use for |
|---|---|---|
| `local` (default) | `~/.claude.json` under the project path | Personal servers / personal credentials for one repo |
| `project` | `.mcp.json` at repo root (commit) | Servers the whole team needs |
| `user` | `~/.claude.json` | Personal servers in every project |

Add:

```bash
claude mcp add --transport http <name> <url> --scope project [--header "Authorization: Bearer ${TOKEN}"]
claude mcp add --transport stdio --scope project --env KEY=value <name> -- <command> [args...]
claude mcp add-json <name> '<json>'
claude mcp list | get <name> | remove <name>
```

`.mcp.json`:

```json
{
  "mcpServers": {
    "api": { "type": "http", "url": "${API_BASE_URL:-https://api.example.com}/mcp", "headers": { "Authorization": "Bearer ${API_TOKEN}" } },
    "db": { "command": "npx", "args": ["-y", "some-mcp-server"], "env": { "DATABASE_URL": "${DATABASE_URL}" } }
  }
}
```

- `${VAR}` / `${VAR:-default}` expand in command, args, env, url, headers. Never commit literal secrets.
- Project servers need approval per user (`enableAllProjectMcpServers`, `enabledMcpjsonServers`, `disabledMcpjsonServers`; ignored in untrusted folders). Reset with `claude mcp reset-project-choices`.
- Cost: with tool search (default) only tool names + server instructions load until a tool is used. Results are capped by `MAX_MCP_OUTPUT_TOKENS` (25k). A CLI (`gh`, `aws`, `gcloud`, `sentry-cli`) is cheaper than an MCP server that wraps it.
- Recommend an MCP server only for: no CLI exists, it needs auth/state the CLI can't do, or it adds real capability (browser automation, live docs like context7, DB introspection).
- Code-intelligence (LSP) plugins cut exploratory reads for typed languages.

## Plugins

Layout (components at plugin root, never inside `.claude-plugin/`):

```
my-plugin/
├── .claude-plugin/plugin.json   # name (kebab-case, required), version, description, author, ...
├── skills/<name>/SKILL.md
├── agents/*.md
├── hooks/hooks.json             # {"hooks": {...}}
├── .mcp.json
├── output-styles/, bin/ (on Bash PATH), settings.json (only `agent`, `subagentStatusLine`)
```

- Plugin names can't start with `claude-`, `anthropic-`, `cc-plugin-`. A root `CLAUDE.md` in a plugin is not loaded: put instructions in a skill.
- `${CLAUDE_PLUGIN_ROOT}` = install dir (changes on update); `${CLAUDE_PLUGIN_DATA}` = persistent data dir.
- `version` pins users: they only get updates when you bump it.
- `userConfig` declares install-time options (`${user_config.KEY}` in MCP/LSP config, skill/agent content).
- Plugin agents ignore `permissionMode`, `hooks`, `mcpServers`, `initialPrompt`.
- Validate: `claude plugin validate <path> [--strict]`. Test without installing: `claude --plugin-dir <path>`. Cost: `claude plugin details <name>`.

## Marketplaces

`.claude-plugin/marketplace.json` at repo root:

```json
{
  "name": "my-marketplace",
  "owner": { "name": "Team" },
  "plugins": [ { "name": "my-plugin", "source": "./plugins/my-plugin", "description": "..." } ]
}
```

Sources: `"./path"`, `{"source":"github","repo":"o/r","ref":"v1"}`, `{"source":"url","url":"https://...git"}`, `{"source":"git-subdir","url":"...","path":"plugins/x"}`, `npm`, `archive`.

Install:

```bash
claude plugin marketplace add owner/repo            # or /plugin marketplace add owner/repo
claude plugin install my-plugin@my-marketplace --scope project   # user (default) | project | local
claude plugin update my-plugin@my-marketplace
```

Team distribution (commit `.claude/settings.json`):

```json
{
  "extraKnownMarketplaces": { "my-marketplace": { "source": { "source": "github", "repo": "owner/repo" } } },
  "enabledPlugins": { "my-plugin@my-marketplace": true }
}
```

Teammates trust the folder, then run `claude plugin install my-plugin@my-marketplace --scope project` once (enabling doesn't download). Third-party marketplaces don't auto-update by default: enable it in `/plugin` → Marketplaces, or run `claude plugin update`.

Disable a team plugin just for yourself: `"enabledPlugins": {"x@mkt": false}` in `.claude/settings.local.json`.
