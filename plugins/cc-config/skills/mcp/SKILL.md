---
description: Add, scope, or prune MCP servers for this project, preferring CLIs when they're cheaper and keeping secrets out of committed files.
argument-hint: "<service or capability, e.g. 'postgres', 'browser testing'>"
disable-model-invocation: true
---

# Configure MCP servers

Request: $ARGUMENTS

1. If the request is empty or vague, ask in one AskUserQuestion call (max 3 questions, skip what's known):
   - Which service or capability, and what should Claude do with it?
   - For the team (`.mcp.json`, committed) or just you (local or user scope)?
   - Where do credentials come from (env var names; never paste secrets here)?
2. Delegate to the `cc-config:config-agent` subagent and wait for its result:
   > mode: apply. Configure MCP for the project in the current directory. Request: <request + answers>. Follow `cc-config ref mcp`: first check whether an installed CLI (gh, aws, gcloud, psql, sentry-cli, ...) already covers it and recommend that instead if so. Otherwise find the official server (verify the package/URL from its official docs or repo, never guess), add it with `claude mcp add` at the chosen scope or merge it into `.mcp.json`, use `${VAR}` for every secret, keep tool search on. If asked to prune, list servers with their scope and disable or remove the unused ones for this project. Report servers added/removed, scope, required env vars, and how to authenticate (`/mcp`).
3. **First run or plan approval.** If the report has `## Interview` or a plan awaiting approval, follow its `Caller:` line: ask with AskUserQuestion, then send the answers or the approved step numbers back (resume the same subagent if you can). Repeat until it reports changes.
4. Relay the report. Remind the user that project servers need a one-time approval in a new session.
