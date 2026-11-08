# Changelog

## 1.1.0 (2026-11-08)

- The agent analyzes the existing config at the start of every run (`cc-config audit` + `validate` + its plan) and opens every report with `## Current state`.
- First run in a project: the agent writes a config plan (`plan.md` in its agent-memory folder) and returns interview questions. The main session asks them (subagents can't ask the user directly), then the agent finalizes the plan and applies only the steps you approve.
- Later runs follow the plan: new requests become plan steps, applied steps are marked done with a dated log.
- `cc-config audit` reports the plan's status, or that this is a first run. New `cc-config ref interview` and `cc-config template plan`.
- `/cc-config:setup` now lets the agent pick the interview questions from its analysis instead of asking fixed ones up front. All slash commands pass interview answers and approvals back to the agent.

## 1.0.0 (2026-11-06)

First release of the `cc-config` plugin.

- `config-agent` subagent: creates, audits and optimizes Claude Code configuration with token cost as the first constraint. Preloads `config-knowledge`, keeps a project profile and decision log in its agent memory, verifies details against live docs.
- `config-knowledge` skill: decision tables, scopes, golden rules, and references (tokens, memory, settings, hooks, subagents, skills, MCP/plugins, docs), verified against Claude Code 2.1.284 docs.
- User-only slash commands (zero tokens until used): `setup`, `audit`, `optimize`, `agent`, `skill`, `memory`, `settings`, `hooks`, `mcp`.
- `cc-config` helper on the Bash PATH: `audit` (token footprint by layer + findings), `validate`, `ref`, `template`, `list`.
- Templates: CLAUDE.md, rule, agent, skill, settings, status line, and hooks (protect files, format on edit, block dangerous Bash, filter test output).
- Always-on cost measured with `/context`: ~211 tokens per session.
