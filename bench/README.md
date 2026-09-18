# bench

Everything needed to rerun the numbers in the root README. No model output in this folder is trusted; every run is graded by tests the model never saw.

## What is here

- `fixtures/<task>/` — a small Node project with a precise `README.md` spec, a deliberately wrong implementation under `lib/`, and a few visible tests under `test/`. Four tasks: `slug` (one file, 17 hidden cases), `limiter` (one file, 10), `ledger` (four modules, 13, plus one **visible test that contradicts the spec** on purpose), and `review` (a file with 11 planted bugs of mixed severity, for code-review recall; no tests, graded by `grade-review.js`).
- `hidden/<task>.hidden.test.js` — the hidden suite. Copied into a run only at grading time.
- `reference/` — a known-good solution per task, used only to prove the hidden tests are fair.
- `prompts/precise_<task>.txt` — the prompt used for the model-vs-model and skill-vs-no-skill runs. `prompts/vague_<task>.txt` — the one-line prompts used to test `prompt-master` on vague requests. `prompts/review_only_critical.txt` — the review prompt with the severity filter Anthropic documents as a recall trap.
- `validate.sh` — proves the fixtures: reference passes every hidden test, buggy code fails most.
- `run.sh` — one headless run: fresh copy of a fixture in a fresh git repo, `claude -p`, JSON result saved.
- `grade.js` — hidden tests, visible tests, files changed, cost, time, thinking tokens, and for `ledger` whether the run followed the spec over the wrong test and said so.
- `grade-review.js` — for the `review` task: which of the 11 planted bugs each report mentions (regex over the report; read `graded-review.json` before quoting).

## Reproduce

```bash
bench/validate.sh                                   # fixtures are fair
bench/run.sh ledger claude-sonnet-5 sonnet-low 1 --effort low
bench/run.sh ledger claude-sonnet-5 sonnet-low 2 --effort low
bench/run.sh ledger opus opus-raw 1
bench/run.sh ledger opus opus-skill 1 --skill archive/fable-mode/SKILL.md
bench/run.sh ledger claude-sonnet-5 sonnet-pm 1 --prompt bench/prompts/vague_ledger.txt --skill prompt-master/SKILL.md
bench/run.sh review claude-sonnet-5 sonnet-review-pm 1 --prompt bench/prompts/review_only_critical.txt --skill prompt-master/SKILL.md
node bench/grade.js "$TMPDIR/claude-skills-bench/runs"
node bench/grade-review.js "$TMPDIR/claude-skills-bench/runs"
```

To test the runner itself without making a model call:

```bash
bench/test-runner.sh
```

The test substitutes a local fake `claude` executable and verifies that relative
`--prompt`, `--skill`, and `--out` paths are resolved from the caller's working
directory. It also verifies that missing inputs and unknown options fail before
Claude is invoked or an existing run directory is replaced.

Runs are independent, so launch several in the background and grade when they finish. Each ledger run costs roughly $0.35 on Sonnet, $1.10 on Opus 5, $1.75 on Fable 5.1 at list price.

## Rules the numbers were produced under

- **Hidden tests decide correctness.** Visible tests are a subset of the spec; the implementation must satisfy the spec.
- **The `Skill` tool is disallowed in every run**, so a skill installed in `~/.claude/skills/` cannot auto-trigger inside a baseline arm. A skill is tested only by appending its `SKILL.md` to the system prompt with `--skill`.
- **Never run from a directory under `~/.claude/`.** Claude Code treats it as protected and blocks every Edit and Write, which silently invalidates the batch (this happened once; twelve runs were discarded).
- **One run tells you nothing.** Two runs per cell showed consistent cost gaps; it does not estimate them precisely. Say so when quoting.
- **Validate before spending.** If `validate.sh` doesn't show the reference at 100% and the buggy code near the floor, fix the fixture, not the model.
