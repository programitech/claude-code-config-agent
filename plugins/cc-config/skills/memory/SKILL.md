---
description: Create, trim, or restructure Claude Code memory (CLAUDE.md, path-scoped rules, CLAUDE.local.md, auto memory, compact instructions) from your requirements.
argument-hint: "[what to remember or change]"
disable-model-invocation: true
---

# Configure memory

Request: $ARGUMENTS

1. If the request is empty, ask in one AskUserQuestion call (max 3 questions):
   - Goal: create a CLAUDE.md, add or update instructions, slim down an existing CLAUDE.md, or change auto memory?
   - For the team (`CLAUDE.md`, `.claude/rules/`) or just you (`CLAUDE.local.md`, `~/.claude/CLAUDE.md`)?
   - Auto memory: keep on, turn off, or move it to another folder?
2. Delegate to the `cc-config:config-agent` subagent and wait for its result:
   > mode: apply. Configure Claude Code memory for the project in the current directory. Request: <request + answers>. Follow `cc-config ref memory`: put each instruction in its cheapest correct home (root CLAUDE.md only for what every task needs, `.claude/rules/` with `paths:` for file-type rules, subdirectory CLAUDE.md for modules, skills for procedures, hooks for must-never-break rules). Keep root CLAUDE.md under 200 lines (aim for 100), derive commands from the real manifests (never invent them), add `# Compact instructions`, don't duplicate existing content, never drop an instruction without saying where it moved. Validate, then report changes and before → after memory tokens.
3. Relay the report.
