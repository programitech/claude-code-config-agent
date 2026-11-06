# Changelog

## 1.0.0 (2026-11-06)

First release of the `cc-config` plugin.

- `config-agent` subagent: creates, audits and optimizes Claude Code configuration with token cost as the first constraint. Preloads `config-knowledge`, keeps a project profile and decision log in its agent memory, verifies details against live docs.
- `config-knowledge` skill: decision tables, scopes, golden rules, and references (tokens, memory, settings, hooks, subagents, skills, MCP/plugins, docs), verified against Claude Code 2.1.284 docs.
- User-only slash commands (zero tokens until used): `setup`, `audit`, `optimize`, `agent`, `skill`, `memory`, `settings`, `hooks`, `mcp`.
- `cc-config` helper on the Bash PATH: `audit` (token footprint by layer + findings), `validate`, `ref`, `template`, `list`.
- Templates: CLAUDE.md, rule, agent, skill, settings, status line, and hooks (protect files, format on edit, block dangerous Bash, filter test output).
- Always-on cost measured with `/context`: ~211 tokens per session.
