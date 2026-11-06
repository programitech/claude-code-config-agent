---
description: Create or improve a Claude Code skill (slash command) from your requirements, using progressive disclosure and the right invocation settings.
argument-hint: "<workflow the skill should run>"
disable-model-invocation: true
---

# Create or improve a skill

Requirements: $ARGUMENTS

1. If the requirements are empty or vague, ask in one AskUserQuestion call (max 3 questions, skip what's known):
   - What workflow should it run, with which inputs (arguments)?
   - Who triggers it: only you with `/name` (zero token cost, needed for anything with side effects), Claude automatically when relevant, or both?
   - For the team (`.claude/skills/`, committed) or just you (`~/.claude/skills/`)?
2. Delegate to the `cc-config:config-agent` subagent and wait for its result:
   > mode: apply. Create a skill, or update the existing one if a skill with this purpose already exists. Requirements: <requirements + answers>. Follow `cc-config ref skills` and `cc-config template skill`: one job, description under 300 chars with concrete triggers, `disable-model-invocation: true` if user-triggered or side-effecting, `argument-hint` when it takes input, SKILL.md under 500 lines with long material in linked supporting files, deterministic steps as scripts in the skill folder, `context: fork` if its work is verbose. Validate, then report the path, how to invoke it, and its per-session token cost (0 if user-only).
3. Relay the report, including the exact command to run it (`/<name> <args>`).
