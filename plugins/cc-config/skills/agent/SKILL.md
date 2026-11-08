---
description: Create or improve a Claude Code subagent from your requirements, with minimal tools, the cheapest capable model, and a short description.
argument-hint: "<what the agent should do>"
disable-model-invocation: true
---

# Create or improve a subagent

Requirements: $ARGUMENTS

1. If the requirements are empty or vague, ask in one AskUserQuestion call (max 3 questions, skip what's known):
   - What should it do, and when should Claude hand work to it automatically (or only when asked)?
   - Read-only (review/research) or may it edit files and run commands?
   - For the team (`.claude/agents/`, committed) or just you (`~/.claude/agents/`)? Cost preference: cheapest (haiku), balanced (sonnet), or same as main model?
2. Delegate to the `cc-config:config-agent` subagent and wait for its result:
   > mode: apply. Create a subagent, or update the existing one if an agent with this purpose already exists. Requirements: <requirements + answers>. Follow `cc-config ref agents` and `cc-config template agent`: description under 400 chars with no `<example>` blocks, minimal `tools`, cheapest capable `model`, `maxTurns`, compact output format, `memory`/`omitClaudeMd` only if justified. Check its description doesn't overlap existing agents. Validate, then report the file path, name, description, tools, model, and the per-session token cost of its description.
3. **First run or plan approval.** If the report has `## Interview` or a plan awaiting approval, follow its `Caller:` line: ask with AskUserQuestion, then send the answers or the approved step numbers back (resume the same subagent if you can). Repeat until it reports changes.
4. Relay the report. Tell the user how to use it: describe the task naturally, or mention `@agent-<name>`; it is available in new sessions (or after `/agents` reload).
