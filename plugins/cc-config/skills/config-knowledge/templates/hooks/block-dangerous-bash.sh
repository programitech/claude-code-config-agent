#!/usr/bin/env bash
# PreToolUse hook (matcher: "Bash"). Blocks destructive commands that permission rules can miss
# (e.g. "git -C . push --force"). Exit 2 blocks; stderr explains why to Claude.
input=$(cat)
if command -v jq >/dev/null 2>&1; then
  cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // empty')
else
  cmd=$(printf '%s' "$input" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null)
fi
[ -z "$cmd" ] && exit 0

# Extended regexes. Edit for the project.
rules=(
  'rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f?[a-zA-Z]*[[:space:]]+(/|~|\$HOME|\*)([[:space:]]|$)'
  'git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push[[:space:]].*(--force|-f)([[:space:]]|$)'
  'git[[:space:]]+reset[[:space:]]+--hard[[:space:]]+origin'
  '(curl|wget)[^|]*\|[[:space:]]*(sudo[[:space:]]+)?(ba|z)?sh'
  'chmod[[:space:]]+-R[[:space:]]+777'
  '(^|[[:space:]])(mkfs|dd[[:space:]]+if=)'
  'DROP[[:space:]]+(DATABASE|TABLE)'
)
for r in "${rules[@]}"; do
  if printf '%s' "$cmd" | grep -Eiq -- "$r"; then
    echo "Blocked by .claude/hooks/block-dangerous-bash.sh (pattern: $r). Ask the user to run it themselves if it is intended." >&2
    exit 2
  fi
done
exit 0
