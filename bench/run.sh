#!/bin/bash
# One benchmark run. Copies a fixture into a fresh git repo, runs headless Claude Code on it, saves the JSON result.
#
#   bench/run.sh <task> <model-id> <label> <n> [--effort LEVEL] [--skill path/to/SKILL.md] [--prompt path] [--out DIR]
#
#   task      slug | limiter | ledger | review (see bench/fixtures)
#   model-id  e.g. claude-sonnet-5, opus, claude-opus-4-8, claude-fable-5-1
#   label     free text used in the run id, e.g. sonnet-low-raw
#   n         run number
#   --skill   append this SKILL.md to the system prompt (the "with skill" arm)
#   --prompt  prompt file (default: bench/prompts/precise_<task>.txt)
#   --out     runs directory (default: $TMPDIR/claude-skills-bench/runs). Do NOT use a directory under
#             ~/.claude: Claude Code treats it as protected and every Edit/Write is blocked.
#   Relative --skill, --prompt, and --out paths are resolved from the caller's working directory.
set -e
CALLER_PWD=$PWD
HERE="$(cd "$(dirname "$0")" && pwd)"
T=$1; MID=$2; L=$3; N=$4; shift 4
EFFORT=""; SKILL=""; PROMPT="$HERE/prompts/precise_$T.txt"; OUT="${TMPDIR:-/tmp}/claude-skills-bench/runs"
while [ $# -gt 0 ]; do case "$1" in --effort) EFFORT=$2; shift 2;; --skill) SKILL=$2; shift 2;; --prompt) PROMPT=$2; shift 2;; --out) OUT=$2; shift 2;; *) echo "unknown arg $1"; exit 1;; esac; done
case "$PROMPT" in /*) ;; *) PROMPT="$CALLER_PWD/$PROMPT";; esac
case "$OUT" in /*) ;; *) OUT="$CALLER_PWD/$OUT";; esac
if [ -n "$SKILL" ]; then
  case "$SKILL" in /*) ;; *) SKILL="$CALLER_PWD/$SKILL";; esac
fi
EXTRA=(); [ -n "$EFFORT" ] && EXTRA+=(--effort "$EFFORT")
if [ -n "$SKILL" ]; then
  SKILL_CONTENT=$(cat "$SKILL" && printf x); SKILL_CONTENT=${SKILL_CONTENT%x}
  EXTRA+=(--append-system-prompt "$SKILL_CONTENT")
fi
PROMPT_CONTENT=$(cat "$PROMPT" && printf x); PROMPT_CONTENT=${PROMPT_CONTENT%x}
ID="$T-$L-$N"; D="$OUT/$ID"; mkdir -p "$OUT"; rm -rf "$D"; cp -R "$HERE/fixtures/$T" "$D"; cd "$D"
git init -q && git add -A && git -c user.email=bench@local -c user.name=bench commit -qm fixture
start=$(date +%s)
# CLAUDECODE is unset so the run works from inside another Claude Code session. Skill is disallowed so an
# installed copy of a skill cannot auto-trigger in the baseline arm.
env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT claude -p "$PROMPT_CONTENT" --model "$MID" --output-format json --max-turns 80 --max-budget-usd 6 \
  --disallowedTools Skill --allowedTools "Read,Edit,Write,Glob,Grep,Bash(node:*),Bash(ls:*),Bash(cat:*)" --permission-mode acceptEdits \
  "${EXTRA[@]}" > "$OUT/$ID.json" 2> "$OUT/$ID.err" || true
echo "wall=$(( $(date +%s) - start ))" > "$OUT/$ID.done"
echo "$ID done ($(cat "$OUT/$ID.done"))"
