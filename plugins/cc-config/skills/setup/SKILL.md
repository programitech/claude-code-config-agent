---
description: Set up or overhaul this project's Claude Code configuration from your requirements (memory, settings, permissions, compaction, hooks, agents, skills, MCP), optimized for token cost.
argument-hint: "[requirements, e.g. 'team repo, strict security, lowest cost']"
disable-model-invocation: true
---

# Claude Code setup

User requirements: $ARGUMENTS

1. **Requirements.** Ask only what the requirements above don't answer, in one AskUserQuestion call, at most 4 questions:
   - Who uses this config: only me (local/user scope) or the whole team (committed project files)?
   - Priority: lowest token cost, balanced, or maximum capability?
   - Guardrails: protect secrets and lockfiles, block destructive commands, auto-format on edit?
   - Extras: subagents (e.g. reviewer, test runner), skills for repeated workflows, MCP integrations, status line with context/cost?
2. **Plan.** Delegate to the `cc-config:config-agent` subagent and wait for its result:
   > mode: plan. Set up or overhaul Claude Code configuration for the project in the current directory. Requirements: <requirements + answers>. Audit what exists first, then return a numbered plan; each item: file, scope, what changes, why, token impact. Keep it to the items that matter most.
3. **Approve.** Show the plan compactly and ask which items to apply (AskUserQuestion with multiSelect, or a reply with item numbers).
4. **Apply.** Delegate to `cc-config:config-agent` again (continue the same subagent if you can):
   > mode: apply. Apply exactly these approved items: <items verbatim>. Validate, then report changes and before → after overhead.
5. **Finish.** Relay the report. Tell the user to start a new session (or run `/reload-plugins`) so the new config loads on a fresh prompt cache, and to commit the shared files if this is a team setup.
