# HeroBrowser real-task check — 2026-11-06

The real `game-ui` agent of the HeroBrowser project (`claude -p --agent game-ui`), run on a code-only snapshot of the commit before `c40f4d02`, asked to write a new pure UI module from a written brief. Graded by the project's own `src/ui/lethalLookahead.tests.ts` from `c40f4d02` (10 checks), which the agent never saw, plus the agent's own tests, `tsc --noEmit`, and the list of files changed. Only the agent's frontmatter differs between arms (the "new" arm preloaded the 2026-11-06 rewrite under the name `sonnet-lean-new`). Two runs per arm.

| Arm | Hidden | Cost | Wall |
|---|---|---|---|
| cur: Sonnet, old sonnet-lean preloaded, no effort | 10/10 ×2 | $0.239, $0.279 | 36 s, 67 s |
| new: Sonnet, rewritten sonnet-lean preloaded | 10/10 ×2 | $0.234, $0.223 | 46 s, 39 s |
| nolean: Sonnet, no preload | 10/10 ×2 | $0.227, $0.228 | 46 s, 44 s |
| med: Sonnet, no preload, `effort: medium` | 10/10 ×2 | $0.225, $0.224 | 41 s, 46 s |
| haiku: Haiku 5.5, no preload, `effort: medium` | 10/10 ×2 | $0.030, $0.025 | 82 s, 74 s |

Every run: own tests pass, typecheck clean, only the two requested files changed. The grader was run once while other runs were in progress (it copies the hidden test in for a few seconds); no run's transcript mentions it.

**What is published here:** the scores, costs and times (`graded.json`) and this summary. HeroBrowser is a private project, so its code snapshot, agent definitions, the task brief and the agents' reports are not included.
