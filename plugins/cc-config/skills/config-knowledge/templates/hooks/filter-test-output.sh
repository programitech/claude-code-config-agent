#!/usr/bin/env bash
# PreToolUse hook (matcher: "Bash"). Rewrites plain test-runner commands so only failures
# reach Claude's context. Based on the official example in https://code.claude.com/docs/en/costs.md
# Requires jq. Fails open (prints {}) when jq is missing or the command isn't a test run.
input=$(cat)
command -v jq >/dev/null 2>&1 || { echo '{}'; exit 0; }
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')

# Edit this pattern to match the project's test commands. Only simple commands are rewritten
# (no pipes, redirects, or chaining), so anything unusual passes through untouched.
pattern='^(npm test|npm run test|pnpm test|yarn test|pytest|go test|cargo test|php artisan test|vendor/bin/phpunit)( [^;&|<>`$#\\[:cntrl:]]*)?$'
if [[ "$cmd" =~ $pattern ]]; then
  # Keeps the real exit code visible as "[exit N]" (works in bash and zsh).
  filtered="{ $cmd 2>&1; echo \"[exit \$?]\"; } | grep -E -A 5 '(FAIL|ERROR|Error|error:|failed|panicked|^\\[exit )' | tail -120"
  printf '%s' "$input" | jq --arg c "$filtered" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", updatedInput: (.tool_input + {command: $c})}}'
else
  echo '{}'
fi
