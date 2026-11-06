# HeroBrowser hard task: does upgrading the agent's model pay? — 2026-11-06

The real `combat-balance` agent (`claude -p --agent combat-balance`), only `model:` changed between arms, on a code-only snapshot of the commit before `298e8358` ("boss-applied enrage ticks on the boss's turn"; engine timing change, no new RNG draws, determinism kept). The brief was written from the commit message. Graded by the project's own `src/systems/combat/tests.ts` from `298e8358` (2228 checks: the new enrage-clock checks plus every older engine check), which the agent never saw; validated first (parent code 2227/2228, the real fix 2228/2228).

| Model | Hidden checks | Cost | Wall | Turns | Ran the balance harness? |
|---|---|---|---|---|---|
| Sonnet 5.5 | 2228/2228 ×2 | $0.50, $0.44 | 92 s, 97 s | 21, 21 | No; warned it should be run |
| Opus 5.5 | 2228/2228 ×2 | $1.34, $1.33 | 507 s, 620 s | 34, 37 | Yes; reported the balance gates it breaks |
| Fable 5.1 | 2228/2228 ×1 | $7.85 | 826 s | 86 | Yes; before/after table of failing gates |

Every run: typecheck clean, its own added tests pass, only `engine.ts`, `tests.ts` (and, in four runs, `types.ts`) changed. All arms inherited the default session effort (no `effort:` in frontmatter).

**What is published here:** the scores, costs and times (`graded.json`) and this summary. HeroBrowser is a private project, so its code snapshot, agent definitions, the task brief and the agents' reports are not included.
