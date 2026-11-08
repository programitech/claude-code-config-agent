---
description: Set up or overhaul this project's Claude Code configuration from your requirements (memory, settings, permissions, compaction, hooks, agents, skills, MCP), optimized for token cost.
argument-hint: "[requirements, e.g. 'team repo, strict security, lowest cost']"
disable-model-invocation: true
---

# Claude Code setup

User requirements: $ARGUMENTS

1. **Analyze.** Delegate to the `cc-config:config-agent` subagent in the foreground and wait for its result:
   > mode: plan. Set up or overhaul Claude Code configuration for the project in the current directory. Requirements: <requirements, or "none given">. Analyze what exists first, then create or update your plan.md. Interview me if the plan needs answers.
2. **Interview.** If the report has `## Interview`, ask those questions with AskUserQuestion exactly as written (one call, up to 4 questions). Send the answers back: resume the same subagent if you can, otherwise delegate again with the original brief plus `answers: <question → choice>`. Repeat once at most if it returns a second round.
3. **Approve.** Show the plan's steps compactly and ask which to apply (AskUserQuestion with multiSelect, or a reply with step numbers). Warn about steps that change team-shared files.
4. **Apply.** Delegate again (resume the same subagent if you can):
   > mode: apply. Apply exactly these approved plan steps: <numbers and titles>. Validate, update plan.md, then report changes and before → after overhead.
5. **Finish.** Relay the report. Tell the user:
   - Start a new session (or run `/reload-plugins`) so the new config loads on a fresh prompt cache.
   - For a team setup, commit the shared files and `.claude/agent-memory/` (the plan lives there).
