#!/bin/bash
# run1.sh <task ledger|review> <arm none|old|new> <n>
S=$SCRATCH
T=$1; A=$2; N=$3; ID="$T-$A-$N"; D=$S/lean/runs/$ID; rm -rf $D; cp -R $S/cs/bench/fixtures/$T $D; cd $D
mkdir -p .claude/agents
SK=""; [ "$A" != none ] && { mkdir -p .claude/skills; cp -R $S/lean/skills/sonnet-lean-$A .claude/skills/; SK=$'skills:\n  - sonnet-lean-'$A; }
cat > .claude/agents/worker.md <<AG
---
name: worker
description: Worker that carries out an implementation or review brief.
model: sonnet
$SK
---
You are a worker subagent. Carry out the brief you are given.
AG
git init -q && git add -A && git -c user.email=b@l -c user.name=b commit -qm fixture
ORCH="Use the Agent tool exactly once, with subagent_type \"worker\", and pass the text inside <brief> as its prompt, verbatim. Do not read, run or edit anything yourself. When the agent returns, output its final report verbatim as your entire answer.
<brief>
$(cat $S/lean/brief_$T.txt)
</brief>"
start=$(date +%s)
env -u CLAUDECODE -u CLAUDE_CODE_ENTRYPOINT claude -p "$ORCH" --model claude-haiku-5-5 --effort high --output-format json --max-turns 20 --max-budget-usd 4 \
  --disallowedTools Skill --allowedTools "Agent,Read,Edit,Write,Glob,Grep,Bash(node:*),Bash(ls:*),Bash(cat:*)" --permission-mode acceptEdits \
  > $S/lean/runs/$ID.json 2> $S/lean/runs/$ID.err
echo "wall=$(( $(date +%s) - start ))" > $S/lean/runs/$ID.done; echo "$ID $(cat $S/lean/runs/$ID.done)"
