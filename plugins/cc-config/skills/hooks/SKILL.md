---
description: Create or fix Claude Code hooks from your requirements (auto-format, protect files, block dangerous commands, filter noisy output, notifications, re-inject context after compaction).
argument-hint: "<when X happens, do Y>"
disable-model-invocation: true
---

# Configure hooks

Requirement: $ARGUMENTS

1. If the requirement is empty or vague, ask in one AskUserQuestion call (max 3 questions, skip what's known):
   - What should happen automatically, and when (before/after which tool, at session start, when Claude stops or needs input)?
   - Should it block the action (guard) or just run alongside it (convenience)?
   - For the team (`.claude/settings.json` + `.claude/hooks/`, committed) or just you (`.claude/settings.local.json` or `~/.claude/settings.json`)?
2. Delegate to the `cc-config:config-agent` subagent and wait for its result:
   > mode: apply. Create or update Claude Code hooks. Requirement: <requirement + answers>. Scope: <scope>. Follow `cc-config ref hooks`; start from a `cc-config template hook:<name> --to .claude/hooks/<name>.sh` copy when one fits and adapt it to this project's tools. Always set a matcher, keep successful runs silent (output costs tokens), exit 2 with a stderr reason to block, prefer `command` hooks over `prompt`/`agent` hooks, guard Stop hooks with `stop_hook_active`. Put scripts in `.claude/hooks/`, `chmod +x`, reference them as `"$CLAUDE_PROJECT_DIR"/.claude/hooks/<name>.sh`, merge into existing settings, and test each script with sample JSON on stdin. Validate, then report the hooks added, what each does, and the test results.
3. Relay the report. Tell the user to check with `/hooks` in a new session.
