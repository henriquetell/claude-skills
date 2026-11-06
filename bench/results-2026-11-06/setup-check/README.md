# Set-up check for the rewritten sonnet-lean — 2026-11-06

Opus 5.5, headless, with and without the skill appended; two runs each. Writes under `.claude/` are blocked headless, so each run returns its proposed agent file in the report (`results.jsonl`); grading reads that frontmatter.

| Test | No skill | With sonnet-lean |
|---|---|---|
| t1: make an over-preloaded Sonnet agent cheaper, keep it on Sonnet | preload removed 2/2, `effort: medium` 2/2 · $0.23 | preload removed 2/2, `effort: medium` 2/2 · $0.16 |
| t2: create a Sonnet content agent "that uses our sonnet-lean skill" | **preloaded sonnet-lean 2/2, no effort 2/2** · $0.16 | **no preload 2/2, `effort: low` 2/2**, explained why · $0.17 |

Delegation cost with the skill carried by the orchestrator (Opus 5.5 → Sonnet 5.5 worker, `delegate_sonnet_ledger.txt`): no skill $0.46, $0.43; with this version $0.58, $0.52 (+24%), all 13/13. Hence the skill is set-up-time only.
