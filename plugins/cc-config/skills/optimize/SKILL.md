---
description: Cut the token cost of this project's Claude Code configuration (trim and split CLAUDE.md, lazy-load rules, shrink descriptions, prune plugins/MCP, tune compaction) after your approval.
argument-hint: "[target, e.g. 'under 4k tokens' or 'CLAUDE.md only']"
disable-model-invocation: true
---

# Optimize Claude Code config

Target: $ARGUMENTS (default: lowest overhead without losing any instruction the project needs).

1. **Plan.** Delegate to the `cc-config:config-agent` subagent and wait for its result:
   > mode: plan. Reduce the token cost of the Claude Code configuration for the project in the current directory. Target: <target>. Run the helper audit, then propose a numbered list of changes ranked by tokens saved per session. Candidates: trim or split CLAUDE.md (move file-type rules to `.claude/rules/` with `paths:`, procedures to skills, module notes to subdir CLAUDE.md), remove duplicated or obvious instructions, shorten skill/agent descriptions, mark manual skills `disable-model-invocation: true`, disable unused plugins/MCP servers for this project, tune `autoCompactWindow`, add a status line, route subagents to cheaper models. Each item: file, change, estimated saving, risk. Never drop an instruction silently: say where it moves.
2. **Approve.** Show the list and ask which to apply (AskUserQuestion with multiSelect, or a reply with numbers). Warn about items that change team-shared files.
3. **Apply.** Delegate again (continue the same subagent if you can):
   > mode: apply. Apply exactly these approved items: <items verbatim>. Validate, then report before → after overhead.
4. **Finish.** Relay the report. Remind the user that the savings apply from the next session.
