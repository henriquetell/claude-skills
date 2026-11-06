#!/bin/bash
# One benchmark run. Copies a fixture into a fresh git repo, runs headless Claude Code on it, saves the JSON result.
#
#   bench/run.sh <task> <model-id> <label> <n> [--effort LEVEL] [--skill path/to/SKILL.md] [--prompt path] [--out DIR]
#
#   task      slug | limiter | ledger          (see bench/fixtures)
#   model-id  e.g. claude-sonnet-5, opus, claude-opus-4-8, claude-fable-5-1
#   label     free text used in the run id, e.g. sonnet-low-raw
#   n         run number
#   --skill   append this SKILL.md to the system prompt (the "with skill" arm)
#   --prompt  prompt file (default: bench/prompts/precise_<task>.txt)
#   BENCH_TOOLS=... (env) overrides the allowed-tools list, e.g. to add Agent for delegation runs
#   --out     runs directory (default: $TMPDIR/claude-skills-bench/runs). Do NOT use a directory under
#             ~/.claude: Claude Code treats it as protected and every Edit/Write is blocked.
set -e
HERE="$(cd "$(dirname "$0")" && pwd)"
T=$1; MID=$2; L=$3; N=$4; shift 4
EFFORT=""; SKILL=""; PROMPT="$HERE/prompts/precise_$T.txt"; OUT="${TMPDIR:-/tmp}/claude-skills-bench/runs"
while [ $# -gt 0 ]; do case "$1" in --effort) EFFORT=$2; shift 2;; --skill) SKILL=$2; shift 2;; --prompt) PROMPT=$2; shift 2;; --out) OUT=$2; shift 2;; *) echo "unknown arg $1"; exit 1;; esac; done
# Resolve --skill/--prompt against the caller's directory before the cd below; relative paths would otherwise
# point inside the fresh fixture copy and the run would silently get an empty prompt or skill.
abspath() { case "$1" in /*) echo "$1";; *) echo "$PWD/$1";; esac; }
[ -n "$SKILL" ] && SKILL=$(abspath "$SKILL"); PROMPT=$(abspath "$PROMPT")
[ -n "$SKILL" ] && [ ! -s "$SKILL" ] && { echo "skill file not found: $SKILL"; exit 1; }
[ -s "$PROMPT" ] || { echo "prompt file not found: $PROMPT"; exit 1; }
ID="$T-$L-$N"; D="$OUT/$ID"; mkdir -p "$OUT"; rm -rf "$D"; cp -R "$HERE/fixtures/$T" "$D"; cd "$D"
git init -q && git add -A && git -c user.email=bench@local -c user.name=bench commit -qm fixture
EXTRA=(); [ -n "$EFFORT" ] && EXTRA+=(--effort "$EFFORT"); [ -n "$SKILL" ] && EXTRA+=(--append-system-prompt "$(cat "$SKILL")")
start=$(date +%s)
# CLAUDECODE is unset so the run works from inside another Claude Code session. Skill is disallowed so an
# installed copy of a skill cannot auto-trigger in the baseline arm.
env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT claude -p "$(cat "$PROMPT")" --model "$MID" --output-format json --max-turns 80 --max-budget-usd 6 \
  --disallowedTools Skill --allowedTools "${BENCH_TOOLS:-Read,Edit,Write,Glob,Grep,Bash(node:*),Bash(ls:*),Bash(cat:*)}" --permission-mode acceptEdits \
  "${EXTRA[@]}" > "$OUT/$ID.json" 2> "$OUT/$ID.err" || true
echo "wall=$(( $(date +%s) - start ))" > "$OUT/$ID.done"
echo "$ID done ($(cat "$OUT/$ID.done"))"
