# bench

Everything needed to rerun the numbers in the root README. No model output in this folder is trusted; every run is graded by tests the model never saw.

## What is here

- `fixtures/<task>/` — a small Node project with a precise `README.md` spec, a deliberately wrong implementation under `lib/`, and a few visible tests under `test/`. Four tasks: `slug` (one file, 17 hidden cases), `limiter` (one file, 10), `ledger` (four modules, 13, plus one **visible test that contradicts the spec** on purpose), and `review` (a file with 11 planted bugs of mixed severity, for code-review recall; no tests, graded by `grade-review.js`).
- `hidden/<task>.hidden.test.js` — the hidden suite. Copied into a run only at grading time.
- `reference/` — a known-good solution per task, used only to prove the hidden tests are fair.
- `prompts/precise_<task>.txt` — the prompt used for the model-vs-model and skill-vs-no-skill runs. `prompts/vague_<task>.txt` — the one-line prompts used to test `prompt-master` on vague requests. `prompts/review_only_critical.txt` — the review prompt with the severity filter Anthropic documents as a recall trap. `prompts/ledger_double_check.txt` — the precise ledger prompt plus the "double-check … final verification" phrases Anthropic documents as over-verification. `prompts/precise_ledger_scope.txt` — the precise ledger prompt plus Anthropic's Sonnet 5.5 "don't add unrequested files" paragraph.  `prompts/delegate_ledger.txt` — the precise ledger prompt with an instruction to delegate the implementation to a subagent (run with `BENCH_TOOLS` including `Agent`).
- `validate.sh` — proves the fixtures: reference passes every hidden test, buggy code fails most.
- `run.sh` — one headless run: fresh copy of a fixture in a fresh git repo, `claude -p`, JSON result saved.
- `grade.js` — hidden tests, visible tests, files changed, cost, time, thinking tokens, and for `ledger` whether the run followed the spec over the wrong test and said so.
- `grade-review.js` — for the `review` task: which of the 11 planted bugs each report mentions (regex over the report; read `graded-review.json` before quoting).

## Reproduce

```bash
bench/validate.sh                                   # fixtures are fair
bench/run.sh ledger claude-haiku-5-5 haiku 1
bench/run.sh ledger claude-sonnet-5-5 sonnet-low 1 --effort low
bench/run.sh ledger claude-opus-5-5 opus 1
bench/run.sh ledger claude-sonnet-5-5 sonnet-pm 1 --prompt bench/prompts/vague_ledger.txt --skill prompt-master/SKILL.md
bench/run.sh review claude-opus-5-5 opus-review-pm 1 --prompt bench/prompts/review_only_critical.txt --skill prompt-master/SKILL.md
node bench/grade.js "$TMPDIR/claude-skills-bench/runs"          # coding tasks; skips review-* runs
node bench/grade-review.js "$TMPDIR/claude-skills-bench/runs"   # review-* runs
```

Runs are independent, so launch several in parallel and grade when they finish. Put one job per line in a file (the arguments of `run.sh`, without `bench/run.sh`) and run `xargs -P 8 -L 1 bash bench/run.sh < jobs.txt`. Don't use `xargs -I{}`: on macOS it silently drops any command line over 255 bytes. Paths given to `--skill` and `--prompt` may be relative to where you call `run.sh` from (before 2026-11-06 they had to be absolute; relative ones silently produced an empty prompt or skill), and must not contain spaces when passed through `xargs`.

Each ledger run costs roughly $0.02 on Haiku 5.5, $0.20 on Sonnet 5.5, $0.42 on Opus 5.5 at list price (2026-11-06). On the 2026-09-09 models: $0.35 on Sonnet 5, $1.10 on Opus 5, $1.75 on Fable 5.1. Results of the 2026-11-06 rerun are in `results-2026-11-06/`.

## Rules the numbers were produced under

- **Hidden tests decide correctness.** Visible tests are a subset of the spec; the implementation must satisfy the spec.
- **The `Skill` tool is disallowed in every run**, so a skill installed in `~/.claude/skills/` cannot auto-trigger inside a baseline arm. A skill is tested only by appending its `SKILL.md` to the system prompt with `--skill`.
- **Never run from a directory under `~/.claude/`.** Claude Code treats it as protected and blocks every Edit and Write, which silently invalidates the batch (this happened once; twelve runs were discarded).
- **One run tells you nothing.** Two runs per cell showed consistent cost gaps; it does not estimate them precisely. Say so when quoting.
- **Validate before spending.** If `validate.sh` doesn't show the reference at 100% and the buggy code near the floor, fix the fixture, not the model.
