---
name: config-knowledge
description: Claude Code configuration rules and references (CLAUDE.md/memory, settings, permissions, compaction, hooks, subagents, skills, MCP, plugins) with token-cost guidance. Use before creating or changing Claude Code config files.
user-invocable: false
---

# Claude Code config knowledge

Verified for Claude Code 2.1.284 on 2026-11-06. If `claude --version` is newer and a detail matters, or a detail is missing, verify it live (`cc-config ref docs` shows the cheap method).

## Knowledge on demand

The plugin puts a `cc-config` command on the Bash PATH. Use it instead of reading plugin files (they sit outside the project, so direct reads trigger permission prompts). Run only what the task needs.

| Task | Run |
|---|---|
| Any change: cost model, budgets, anti-patterns, compaction | `cc-config ref tokens` |
| CLAUDE.md, rules, imports, auto/agent memory | `cc-config ref memory` |
| settings.json, permissions, env vars, model/effort, status line, output styles | `cc-config ref settings` |
| Hooks | `cc-config ref hooks` |
| Subagents | `cc-config ref agents` |
| Skills / slash commands | `cc-config ref skills` |
| MCP servers, plugins, marketplaces | `cc-config ref mcp` |
| Checking live docs cheaply | `cc-config ref docs` |

Templates: `cc-config template <name>` prints one (fill it in, then write the finished file once). `--to <path>` copies a script into place without passing its text through context and keeps its exec bit: use it for `hook:*` and `statusline` only. Names: `claude-md`, `rule`, `agent`, `skill`, `settings`, `statusline`, `hook:protect-files`, `hook:format-on-edit`, `hook:block-dangerous-bash`, `hook:filter-test-output`. Fill every placeholder.

Measure and check (run them, never read their code):

```bash
cc-config audit    [--project DIR] [--json]   # token footprint of every always-loaded layer + findings
cc-config validate [--project DIR] [--json]   # settings, hooks, agents, skills, .mcp.json; exit 1 on errors
```

If `cc-config` is not on PATH, use `python3 "${CLAUDE_PLUGIN_ROOT}/bin/cc-config" <args>`.

## What loads when

- **Every request**: CLAUDE.md chain + imports, rules without `paths`, MEMORY.md (200 lines), names+descriptions of model-invocable skills/commands, agent descriptions, MCP tool names, output style.
- **On demand**: rules with `paths`, subdirectory CLAUDE.md, skill bodies, supporting files, MCP tool schemas.
- **Isolated (billed, but out of the main context)**: subagent runs, `context: fork` skills.
- **Zero model tokens**: hooks that print nothing, status line, permissions, settings, `disable-model-invocation: true` skills until invoked.

## Where does a requirement go?

| Requirement | Mechanism | Location |
|---|---|---|
| Every task in this repo needs it | CLAUDE.md bullet | `./CLAUDE.md` (≤200 lines) |
| Only for some files/dirs | Path-scoped rule | `.claude/rules/<topic>.md` with `paths:` |
| Only for one module | Subdirectory memory | `<module>/CLAUDE.md` |
| Procedure the user triggers | User-only skill | `.claude/skills/<name>/SKILL.md` + `disable-model-invocation: true` |
| Knowledge Claude should pull in when relevant | Skill | `.claude/skills/<name>/` (`user-invocable: false` if never typed) |
| Must always / never happen | Hook or permission rule | `.claude/settings.json` |
| Verbose or specialized work, separate context, cheaper model | Subagent | `.claude/agents/<name>.md` |
| External system without a good CLI | MCP server | `.mcp.json` (team) or `claude mcp add --scope local` |
| Personal preference | User or local scope | `~/.claude/...` or `.claude/settings.local.json`, `CLAUDE.local.md` |
| Same setup across many repos | Plugin | marketplace repo |

## Scopes

- Team-shared, committed: `CLAUDE.md`, `.claude/settings.json`, `.claude/rules/`, `.claude/skills/`, `.claude/agents/`, `.mcp.json`, `.claude/agent-memory/`.
- Personal for this repo: `.claude/settings.local.json`, `CLAUDE.local.md`, local MCP scope, `.claude/agent-memory-local/`.
- Personal everywhere: `~/.claude/settings.json`, `~/.claude/CLAUDE.md`, `~/.claude/{skills,agents,rules}/`.
- Precedence: managed > CLI > local > project > user (arrays merge).

## Golden rules

1. Smallest config that meets the requirement. Each always-loaded line must earn its tokens every request.
2. Prefer lazy mechanisms (path rules, skills, subdir CLAUDE.md, subagents) over always-loaded memory.
3. Descriptions are the always-on cost: skills under ~300 chars, agents under ~400, no `<example>` blocks.
4. Deterministic needs → hooks/permissions, not prose. Deterministic work → scripts, not instructions.
5. Least privilege: minimal `tools` per agent; deny-list secrets; never allow `Bash` wholesale in team settings; never set `bypassPermissions` in shared files.
6. Cheapest capable model per agent (`haiku` for search/logs/tests, `sonnet` for review/most work, `opus`/`inherit` for hard reasoning).
7. Never put secrets in committed files. Use `${VAR}` expansion and `settings.local.json`.
8. Valid JSON, valid frontmatter, correct field names (unknown fields are silently ignored). Validate after every change.
9. Don't duplicate content across CLAUDE.md, rules, skills, and agents. One home per fact.
10. Config edits invalidate the prompt cache for running sessions: batch them and tell the user to start a fresh session (or `/reload-plugins`).
