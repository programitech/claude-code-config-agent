#!/usr/bin/env bash
# Status line: model | context used | session cost | prompt-cache hit ratio.
# Costs no model tokens. Configure with:
#   "statusLine": {"type": "command", "command": "~/.claude/statusline.sh", "padding": 0}
input=$(cat)
python3 - "$input" <<'PY' 2>/dev/null || echo "claude"
import json, sys
d = json.loads(sys.argv[1] or "{}")
def g(*keys):
    v = d
    for k in keys:
        v = v.get(k) if isinstance(v, dict) else None
    return v
model = g("model", "display_name") or "claude"
used = g("context_window", "used_percentage")
size = g("context_window", "context_window_size")
cost = g("cost", "total_cost_usd")
hit = g("prompt_cache", "hit_ratio")
parts = [model]
if used is not None:
    win = (f" of {size / 1e6:g}M" if size >= 1_000_000 else f" of {round(size / 1000)}k") if size else ""
    parts.append(f"ctx {round(used)}%{win}")
if cost is not None:
    parts.append(f"${cost:.2f}")
if hit is not None:
    parts.append(f"cache {round(hit * 100 if hit <= 1 else hit)}%")
print(" | ".join(parts))
PY
