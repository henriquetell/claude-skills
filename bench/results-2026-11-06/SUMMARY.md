# Bench rerun on the 5.5 models — 2026-11-06

Claude Code 2.1.319, headless `claude -p`, Skill tool disallowed, skill tested by `--append-system-prompt`.
Two runs per cell. Costs are `total_cost_usd` as reported by the CLI. Jobs: `jobs.txt`; raw grades: `graded-*.json`.

## prompt-master

**Review trap** (`review_only_critical.txt`, 11 planted bugs)

| Arm | Recall (run 1, run 2) | Criticals | Mean cost |
|---|---|---|---|
| Sonnet 5.5 raw | 7, 6 | 3/3, 3/3 | $0.13 |
| Sonnet 5.5 + prompt-master | 10, 11 | 3/3, 3/3 | $0.16 |
| Opus 5.5 raw | 2, 7 | 2/3, 3/3 | $0.26 |
| Opus 5.5 + prompt-master | 10, 11 | 3/3, 3/3 | $0.33 |

Earlier baseline (2026-09-09): Sonnet 5 raw 2, 4 → skill 9, 10; Opus 5 raw 10 → skill 11.
Sonnet 5.5 resists the filter better than Sonnet 5 did. Opus 5.5 obeys it more literally than Opus 5 did. The rule pays on both.

**Vague ledger** (`vague_ledger.txt`, visible test contradicts the spec)

| Arm | Hidden | Edited the visible test | Mean cost |
|---|---|---|---|
| Sonnet 5.5 raw | 13/13 ×2 | 2 of 2 | $0.155 |
| Sonnet 5.5 + prompt-master | 13/13 ×2 | 0 of 2 | $0.174 |
| Opus 5.5 raw | 13/13 ×2 | 2 of 2 | $0.334 |
| Opus 5.5 + prompt-master | 13/13 ×2 | 0 of 2 | $0.327 |

The same behavior difference as on 5.0. Cost is now flat to slightly cheaper on Opus.

**Over-verification** (Opus 5.5, precise ledger with and without the double-check phrases; no prompt-master arm)

| Arm | Hidden | Mean cost | Mean wall |
|---|---|---|---|
| precise | 13/13 ×2 | $0.42 | 90 s |
| + "double-check… final verification…" | 13/13 ×2 | $0.53 (+25%) | 136 s (+52%) |

Anthropic's warning still holds on Opus 5.5 (it was +39% on Opus 5).

## sonnet-lean

**Sonnet 5.5 effort sweep** (precise ledger)

| Effort | Hidden | Thinking tok (mean) | Mean cost | Mean wall |
|---|---|---|---|---|
| low | 13/13 ×2 | 475 | $0.19 | 52 s |
| medium | 13/13 ×2 | 745 | $0.20 | 57 s |
| high | 13/13 ×2 | 1,545 | $0.24 | 72 s |

No early check-in stops and no skipped verification seen. One `low` run didn't flag the wrong test in its report.
Sonnet 5 at low was $0.34 on this task; Opus 5.5 precise is now $0.42 (Opus 5: $1.06).

**Haiku 5.5** (precise ledger, default effort): 13/13 ×2, followed the spec, flagged the wrong test, 75–91 s.
Reported cost $0.017–0.026 against ~15–21k output tokens. That looks too low for list price, so check pricing before quoting it.
Either way, Haiku 5.5 cleared a four-module reasoning task, not just mechanical bulk.

## Not measured

The prompt-master arm on the double-check prompt; Sonnet subagents spawned through the Agent tool (preload cost, check-in at medium); Fable 5.1; anything beyond these three fixtures.

---

# Session B — same day, independent runs (files in `session-b/`)

Same harness, run from the claude-skills session. Two runs per cell unless stated. Combined tables are in the root README.

| Cell | Result | Mean cost |
|---|---|---|
| Sonnet 5.5 ledger `low` / `medium` / `high` | 13/13 ×2 each | $0.19 / $0.21 / $0.22 |
| Sonnet 5.5 ledger `medium` + "don't add unrequested files" paragraph | 13/13 ×2, no extra files in either arm | $0.26 (vs $0.21) |
| Sonnet 5.5 ledger, sonnet-lean appended | 13/13 ×2 | $0.25 (vs $0.22 at default effort) |
| Haiku 5.5 ledger `medium` | 13/13 ×2 | $0.022 |
| Haiku 5.5 slug / limiter | 17/17 ×2 / 10/10 ×2 | under $0.01 |
| Opus 5.5 ledger default | 13/13 ×2 | $0.42 |
| Review trap, raw → prompt-master: Haiku 5.5 | 3, 3 → 4 (skill ignored), 11 | $0.004 → $0.010 |
| same, Sonnet 5.5 | 7, 6 → 11, 11 | $0.05 → $0.09 |
| same, Opus 5.5 | 5, 5 → 11, 11 | $0.11 → $0.18 |
| Vague ledger, Sonnet 5.5 raw → prompt-master | test rewritten 1 of 2 → 0 of 2; 13/13 all | $0.18 → $0.20 |
| Double-check ledger, Opus 5.5 raw → prompt-master | 13/13 all; skill removed the phrases in 1 of 2 | $0.50 → $0.37 (stripped) / $0.50 (not) |

**Haiku pricing check.** `ledger-h55-med-1`: 20,399 output × $0.50 + 584,964 cache reads × $0.01 + 38,572 1-hour cache writes × $0.20 (per MTok) = $0.0238, the CLI's `total_cost_usd` exactly. The pricing page lists these rates for Haiku 5.5 prompts up to 100K tokens and 5× above.

## Re-test after the prompt-master trigger fix (§0 strip-list scan first)

| Cell | Result | Mean cost |
|---|---|---|
| Review trap, Haiku 5.5 | 11, 11 (before: 4, 11) | $0.008 |
| Review trap, Sonnet 5.5 | 11, 10 | $0.095 |
| Vague ledger, Sonnet 5.5 | 13/13 ×2, test left alone ×2, rewrite not printed at top ×2 | $0.18 (= raw) |
| Double-check ledger, Opus 5.5 | 13/13 ×2, phrases removed in 1 of 2 (rewrite printed after the summary) | $0.48 / $0.52 (raw $0.50) |

Verdict: the fix made the review rule reliable on Haiku; it did not make the over-verification strip reliable or cost-saving on Opus 5.5.

## Delegation head-to-head: no skill vs old vs new sonnet-lean

Opus 5.5 as orchestrator, `prompts/delegate_ledger.txt` (the precise ledger prompt plus "delegate the implementation to a subagent with the Agent tool, choose the model and write the brief yourself"), `BENCH_TOOLS` adds `Agent`. Old = `sonnet-lean/SKILL.md` at commit 7a918c1; new = the 2026-11-06 rewrite. Two runs each.

| Arm | Hidden | Model Opus picked | Opus cost | Worker cost | Total |
|---|---|---|---|---|---|
| No skill | 13/13 ×2 | Sonnet 5.5 ×2 | $0.22 | $0.24 | $0.46 |
| Old sonnet-lean | 13/13 ×2 | Sonnet 5.5 ×2 | $0.27 | $0.18 | $0.45 |
| New sonnet-lean | 13/13 ×2 | **Haiku 5.5 ×2** | $0.27 | $0.01 | **$0.28** |

New vs no skill: −39%. New vs old: −38%. Old vs no skill: −2% (noise). Reading the skill costs Opus about $0.05 per run; routing the worker to Haiku saves about $0.20. All six followed the spec over the wrong visible test and left `test/` alone.

## Same head-to-head with the worker model fixed to Sonnet 5.5

`prompts/delegate_sonnet_ledger.txt`: as above, but "using model sonnet for it (do not choose another model)". Isolates everything sonnet-lean does except model choice (brief shape, output constraints). Two runs each, all 13/13.

| Arm | Opus cost | Sonnet worker cost | Total |
|---|---|---|---|
| No skill | $0.25, $0.27 | $0.23, $0.25 | $0.50 |
| Old sonnet-lean | $0.25, $0.30 | $0.21, $0.22 | $0.49 |
| New sonnet-lean | $0.29, $0.43 | $0.25, $0.12 | $0.55 (+10%) |

With the model held fixed, neither version saves money; the new one costs slightly more (it is a longer skill for the orchestrator to read, and in one run Opus did much of the work itself). The Agent tool can't set a worker's effort, so the effort lever can't act in this setup. **The whole measured saving of the new sonnet-lean comes from its model-routing rule.**

---

# Session C — worker-side preload (files in `session-c-preload/`)

How HeroBrowser actually uses sonnet-lean: preloaded via `skills:` frontmatter into a `model: sonnet` custom agent. Haiku 5.5 orchestrator (effort high) relays an identical brief verbatim to the `worker` subagent; worker cost = the `claude-sonnet-5-5` entry of `modelUsage`. Preload verified in every subagent transcript (0 hits in `none`, 2 in each skill arm). Three runs per cell.

| Task | Arm | Quality | Worker cost (runs) | Mean |
|---|---|---|---|---|
| ledger | none | 13/13 ×3 | 0.199, 0.177, 0.117 | $0.164 |
| ledger | old sonnet-lean | 13/13 ×3 | 0.159, 0.157, 0.161 | $0.159 |
| ledger | new sonnet-lean | 13/13 ×3 | 0.149, 0.198, 0.140 | $0.162 |
| review | none | 11, 10, 11 of 11 | 0.039, 0.039, 0.041 | $0.040 |
| review | old sonnet-lean | 11, 11, 10 of 11 | 0.050, 0.050, 0.049 | $0.050 (+25%) |
| review | new sonnet-lean | 11, 10, 11 of 11 | 0.054, 0.052, 0.053 | $0.053 (+33%) |

The preload neither helps nor hurts quality. It saves nothing on a ~$0.16 task (within noise; the old version had the tightest spread) and is pure overhead on a short one: output tokens were the same (~1,500), so the +$0.01 is the cost of reading the skill. Combined with Session B: sonnet-lean's measured value is on the caller side (routing), not inside the worker.
