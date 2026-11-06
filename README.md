# Claude Code Config Agent (`cc-config`)

A Claude Code plugin you install into any project instead of rebuilding your Claude Code setup each time. It ships a **config agent** that creates, audits, and maintains everything Claude Code reads (CLAUDE.md and memory, settings and permissions, auto-compact, model and effort, hooks, subagents, skills, MCP servers, status line, plugins), with **token cost as the first constraint** and current official docs as the source of truth.

It builds on Anthropic's [`claude-code-setup`](https://github.com/anthropics/claude-plugins-official/tree/main/plugins/claude-code-setup) plugin. That plugin is read-only and recommends automations. This one also measures cost, applies changes after your approval, validates them, and keeps a decision log per project.

## Install

**In Claude Code**

```text
/plugin marketplace add programitech/claude-code-config-agent
/plugin install cc-config@cc-config-agent
```

Pick a scope when asked: *this repository* (team), *you, in this repo only*, or *you, everywhere*.

**From your shell** (inside the project)

```bash
curl -fsSL https://raw.githubusercontent.com/programitech/claude-code-config-agent/main/install.sh | bash -s -- --scope project --allow-helper
```

`--scope project|local|user` (default `project`). `--allow-helper` adds `Bash(cc-config *)` to that scope's allow list, so the agent can run its read-only helper without prompting.

Or run the CLI commands directly:

```bash
claude plugin marketplace add programitech/claude-code-config-agent
claude plugin install cc-config@cc-config-agent --scope project
```

**For a whole team**: commit this in the repo's `.claude/settings.json` (the installer writes it for you at project scope):

```json
{
  "extraKnownMarketplaces": {
    "cc-config-agent": { "source": { "source": "github", "repo": "programitech/claude-code-config-agent" } }
  },
  "enabledPlugins": { "cc-config@cc-config-agent": true },
  "permissions": { "allow": ["Bash(cc-config *)"] }
}
```

Teammates trust the folder, then run `claude plugin install cc-config@cc-config-agent --scope project` once.

Requirements: Claude Code 2.1.271 or later (older versions ignore some agent fields) and `python3`.

## Use

| Command | What it does |
|---|---|
| `/cc-config:setup [requirements]` | Asks a few questions, audits, proposes a plan, applies what you approve |
| `/cc-config:audit [focus]` | Read-only report: tokens per session, top contributors, ranked fixes |
| `/cc-config:optimize [target]` | Cuts config token cost (split CLAUDE.md into path rules/skills, shrink descriptions, prune plugins/MCP, tune compaction) |
| `/cc-config:agent <description>` | Creates or improves a subagent (minimal tools, cheapest capable model) |
| `/cc-config:skill <workflow>` | Creates or improves a skill / slash command |
| `/cc-config:memory [request]` | CLAUDE.md, `.claude/rules/`, CLAUDE.local.md, auto memory, compact instructions |
| `/cc-config:settings [request]` | Permissions, auto-compact, model/effort, env vars, status line, output style |
| `/cc-config:hooks <when X, do Y>` | Hooks from tested templates (protect files, format on edit, block dangerous commands, filter test output) |
| `/cc-config:mcp <service>` | Adds, scopes, or prunes MCP servers. Prefers a CLI when one exists |

You can also just ask, for example "create an agent that reviews PRs for security issues" or "make auto-compact cheaper". Claude hands config work to `cc-config:config-agent` on its own.

## Token cost

| Part | Cost |
|---|---|
| Agent description + knowledge skill description | **~211 tokens per session** (measured with `/context`) |
| The 9 slash commands | 0 until you run one (`disable-model-invocation: true`) |
| The agent's work | Runs in its own context. Only a short report returns to your chat |

`claude plugin details cc-config` shows ~750 always-on tokens because its estimate also counts user-only skills, which the docs say stay out of context.

How the agent keeps your config cheap:
- Always-loaded memory stays small. File-type rules move to path-scoped `.claude/rules/`, procedures to skills, module notes to subdirectory CLAUDE.md files.
- Manual skills are user-only, and agent and skill descriptions stay short.
- Each subagent gets the cheapest capable model and the fewest tools it needs.
- Compaction is tuned to your model (`autoCompactWindow`), and hooks filter noisy output before it reaches context.
- It reports before → after overhead for every change (`cc-config audit`).
- It looks up docs by extracting only the needed section (`curl` + `sed`), never whole pages (a page can be ~30k tokens).
- It keeps a project profile and decision log in `.claude/agent-memory/cc-config-config-agent/`, so it doesn't re-scan your repo every time.

## Permissions and what it touches

- Claude Code always asks before writing inside `.claude/` or `~/.claude/` (protected paths). Allow rules can't pre-approve this, by design. When prompted, choose **"allow edits to .claude for this session"** once.
- The helper `cc-config` (on the Bash PATH via the plugin's `bin/`) only reads config. The one exception is `template --to`, which copies a template and refuses to overwrite. `--allow-helper` or the `Bash(cc-config *)` rule stops it from prompting.
- The agent never adds `bypassPermissions`, wildcard `Bash` allows, or secrets to shared files, and asks before applying anything beyond your request.
- The agent uses your main session model, or `CLAUDE_CODE_SUBAGENT_MODEL` if you set it (e.g. `sonnet` to save cost).

## Helper CLI

```bash
cc-config audit    [--project DIR] [--json]   # token footprint of every always-loaded layer + findings
cc-config validate [--project DIR] [--json]   # settings, permissions, hooks, agents, skills, .mcp.json
cc-config ref <topic>                         # tokens | memory | settings | hooks | agents | skills | mcp | docs
cc-config template <name> [--to PATH]         # claude-md | rule | agent | skill | settings | statusline | hook:<name>
cc-config list
```

It also works outside Claude Code: `python3 plugins/cc-config/bin/cc-config audit --project ~/code/my-app`.

## Staying current

The references were verified against the Claude Code 2.1.284 docs on 2026-11-06. When your Claude Code is newer, or a detail is missing, the agent checks the live docs and cites them. Maintainers refresh the references with the repo-local `/refresh-references` skill, bump `version` in `plugins/cc-config/.claude-plugin/plugin.json`, and push. Users then get the update with `claude plugin update cc-config@cc-config-agent`, or automatically if they enable auto-update for this marketplace in `/plugin` → Marketplaces. Third-party marketplaces have auto-update off by default.

## Repository layout

```
.claude-plugin/marketplace.json          marketplace "cc-config-agent"
plugins/cc-config/
├── .claude-plugin/plugin.json
├── agents/config-agent.md               the config agent
├── bin/cc-config                        helper (audit, validate, ref, template)
└── skills/
    ├── config-knowledge/                preloaded knowledge: SKILL.md, references/, templates/
    └── setup, audit, optimize, agent, skill, memory, settings, hooks, mcp
install.sh                               installer
.github/workflows/validate.yml           CI: manifests, helper, hook smoke tests
.claude/skills/refresh-references/       maintainer skill
```

## Develop

```bash
claude plugin validate . --strict && claude plugin validate plugins/cc-config --strict
claude --plugin-dir ./plugins/cc-config      # load the working copy for one session
```

## License

MIT
