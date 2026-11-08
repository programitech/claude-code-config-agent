---
description: Configure Claude Code settings from your requirements (permissions, auto-compact, model and effort, token env vars, status line, output style, attribution) at the right scope.
argument-hint: "[what to change, e.g. 'compact earlier, block .env reads']"
disable-model-invocation: true
---

# Configure settings

Request: $ARGUMENTS

1. If the request is empty or vague, ask in one AskUserQuestion call (max 4 questions, skip what's known):
   - What to configure: permissions (allow/deny), auto-compact and context, model/effort, status line, output style, commit attribution, or other?
   - Scope: whole team (`.claude/settings.json`), just you in this repo (`.claude/settings.local.json`), or you everywhere (`~/.claude/settings.json`)?
   - For compaction: compact earlier to save tokens (e.g. at 300k-400k on 1M models), default, or a specific size?
   - For permissions: which commands should run without asking, and what must never be read or run?
2. Delegate to the `cc-config:config-agent` subagent and wait for its result:
   > mode: apply. Configure Claude Code settings. Request: <request + answers>. Scope: <scope>. Follow `cc-config ref settings`: merge into the existing file (never overwrite), keep `$schema`, verify every key and env var name, `*` after the subcommand in Bash rules, deny rules for secrets, no `bypassPermissions`/`Bash` wildcard allows in shared files, compaction via `autoCompactWindow` or `CLAUDE_CODE_AUTO_COMPACT_WINDOW` sized to the user's model. For a status line, install it with `cc-config template statusline --to ~/.claude/statusline.sh` (user scope) unless asked otherwise. Validate, then report each key changed, its scope, and its effect on tokens.
3. **First run or plan approval.** If the report has `## Interview` or a plan awaiting approval, follow its `Caller:` line: ask with AskUserQuestion, then send the answers or the approved step numbers back (resume the same subagent if you can). Repeat until it reports changes.
4. Relay the report. Note that most settings hot-reload, but a new session gives the cleanest result.
