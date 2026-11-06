# claude-skills

Two [Claude Code skills](https://code.claude.com/docs/en/skills) that make Claude cheaper and more accurate. Every rule cites the Anthropic documentation it comes from, every claim of benefit was measured with tests the model never saw, and the benchmark is in [`bench/`](bench/) so you can rerun it.

**What is a skill?** A short instruction file for one kind of task. Claude Code reads each installed skill's one-line description; when your request matches, it opens the file and follows it. You install it once, and it's used on its own when that task comes up, or when you call it by name (`/skill-name`).

| Skill | What it does | Use it when |
|---|---|---|
| [`prompt-master`](prompt-master/SKILL.md) | Rewrites a request into the prompt Claude works best with, shows the rewrite with one reason per change, then does the work from it. | A person's request is vague, carries a severity filter or "double-check everything", or was written for another model. |
| [`sonnet-lean`](sonnet-lean/SKILL.md) | Sets your subagents up so each call costs less: no useless skill preloads, an explicit effort per agent, a model policy for the orchestrator. Used once, at set-up time. | Creating or editing `.claude/agents/*.md`, writing the delegation rules in `CLAUDE.md`, or asking why your agents are expensive. |

## Does it save money?

Measured on 2026-11-06 on Claude Opus 5.5, Sonnet 5.5 and Haiku 5.5. Two to four runs per cell: enough to show a direction, not to size it precisely.

| Situation | Without | With | Verdict |
|---|---|---|---|
| A Sonnet agent on a real project task | $0.26 per call | Set up by `sonnet-lean`: $0.22, same 10/10 | **About 15% cheaper on every call** |
| Small, tested work sent down to Haiku 5.5 | $0.46 (orchestrator picked Sonnet) | $0.28, same 13/13 | **39% cheaper**, where your project allows it |
| Upgrading a hard engine change from Sonnet | Sonnet: $0.47, ~1.5 min, correct | Opus $1.33 / ~9 min, Fable $7.85 / 14 min, both correct | **Upgrade only after a failed check** |
| A review prompt that says "only report critical issues" | 2–7 of 11 bugs found (Opus 5.5) | `prompt-master`: 10–11 of 11, +3–7 cents | **Costs a little more, finds 2–5× the bugs** |
| A vague "get the tests passing" | 5 of 6 runs edited the test to make it pass | `prompt-master`: 0 of 8, same or slightly higher cost | **Protects your tests** |
| A prompt that says "double-check everything" (Opus 5.5) | +19–25% cost for nothing | `prompt-master` removed it in 2 of 4 runs | **Unreliable: delete those phrases yourself** |

## prompt-master: how it works

It runs at the start of a task, before any work:

1. **Scan for harmful instructions first.** Any match from the strip-list below forces a rewrite, even of an otherwise complete request. Then: a request that already states its goal, done-criteria and scope is left alone, and a question is just answered.
2. **Investigate before rewriting.** It reads the spec, tests and files the request points at, and ranks the sources of truth: a written spec over tests, tests over current code.
3. **Rewrite** using nine rules: the goal with its reason, done-criteria that can fail, explicit scope, assessment or change, context as file references, the source of truth and its conflicts, the deliverable's shape, the strip-list, and one batch of questions or numbered assumptions.
4. **Show the rewrite** with one line per change, so the reader learns why.
5. **Do the work from the rewrite**, and report against its done-criteria.

### The strip-list

| If your prompt says | What a current Claude model does | Replaced by |
|---|---|---|
| "only report critical issues", "be conservative", "don't nitpick" | Finds the bugs, then withholds the ones below your bar | Report every issue with a confidence and a severity; filter afterwards |
| "double-check your work", "add a final verification step" | Verifies work it already verifies: more cost, same quality | Removed |
| A numbered step-by-step recipe | Follows the recipe instead of reasoning about the goal | Goal plus constraints |
| "show your reasoning", "explain your thinking in the answer" | Can trigger a `reasoning_extraction` refusal on current models | The conclusion and its evidence |
| "think carefully", "think step by step", "you are a senior engineer", ALL CAPS | Effort already controls thinking | Dropped, so the real instructions stand out |

**Who it's for:** people new to AI coding, people bringing prompt habits from other models, and teams with shared review prompts. Not for briefs Claude writes for its own subagents, or for requests that already are complete briefs.

## sonnet-lean: how it works

**New to it?** [`docs/sonnet-lean.pdf`](docs/sonnet-lean.pdf) explains the skill in nine slides, including what a skill is.

The skill is used once, when you set agents up. It writes its savings into the agent files and `CLAUDE.md`; after that it isn't loaded at all. Putting it inside the agents themselves was measured three times and costs 13–33% more for identical results, because Sonnet 5.5 already works lean and the instruction is just more to read.

1. **No useless preloads.** Every skill in an agent's `skills:` list is read on every call, so the list holds only skills the agent uses for its own work.
2. **An explicit `effort:` per agent.** Without it, an agent thinks as hard as the session that calls it. `low` for mechanical work, `medium` for normal coding, `high` for hard work; avoid `xhigh`/`max` for routine work.
3. **One complete brief**, with the return format built into the agent's definition.
4. **Batch related items** into one agent instead of one agent per item.
5. **Choose each call's model by evidence, in both directions.** Go *down* to Haiku 5.5 for small, well-specified work a test or validator will check: the same result as Sonnet at about a tenth of the cost, though slower. Go *up* to Opus or Fable only after the cheaper run failed a check, never because a task looks hard. The skill writes one of two rules into `CLAUDE.md`: **flexible** (the orchestrator picks the tier per call) or **pinned** (each agent keeps its model).

Asked to create a new Sonnet agent "that uses sonnet-lean", Claude without the skill put it in the agent's preload and set no effort in 2 of 2 runs; with the skill it got the setup right in 2 of 2 and explained why.

## Installation

```bash
git clone https://github.com/henriquetell/claude-skills.git
cp -R claude-skills/prompt-master claude-skills/sonnet-lean ~/.claude/skills/
```

Per-project installation works too: use `.claude/skills/` inside a repository. Run `/skill-doctor` after a few sessions to see what each skill costs in context and whether it is being used.

## Usage

Both skills trigger on their own when a request matches. To call them by name:

```text
/prompt-master fix the login bug          # rewrite, show, then do
/prompt-master --only review this file    # rewrite and show, don't execute
/sonnet-lean                              # when creating or editing agents, or writing the model policy
```

They work at different moments: `sonnet-lean` when you set a project's agents up, `prompt-master` when a person types a request that needs it. Neither belongs in an agent's preload or on every delegation.

## The measurements

Every number comes from [`bench/`](bench/): fixtures with a precise spec, deliberately wrong starting code, and hidden tests validated against a reference solution. Each run is a headless `claude -p` with the skill under test appended to the system prompt and the `Skill` tool disabled, so an installed copy can't leak into the baseline. Full tables, raw grades and harnesses are in [`bench/results-2026-11-06/`](bench/results-2026-11-06/SUMMARY.md).

**Models, same coding task** (four modules, 13 hidden tests):

| | Haiku 5.5 | Sonnet 5.5 `low` | Sonnet 5.5 `high` | Opus 5.5 |
|---|---|---|---|---|
| Hidden tests | 13/13 ×4 | 13/13 ×4 | 13/13 ×4 | 13/13 ×4 |
| Cost per run | $0.02 | $0.19 | $0.22–0.24 | $0.42 |
| Time | ~85 s | ~53 s | ~68 s | ~90 s |

**On a real project** (HeroBrowser, a browser game with an orchestrator and nine agents). Its real agents (`claude -p --agent <name>`) re-did real commits from its history, graded by the project's own tests:

| Task | Setup | Result | Cost | Time |
|---|---|---|---|---|
| UI module (10 checks) | Sonnet, set up as before | 10/10 ×2 | $0.26 | 36–67 s |
| | Sonnet, set up by `sonnet-lean` | 10/10 ×2 | $0.22 | 41–46 s |
| | Haiku 5.5 | 10/10 ×2 | $0.03 | 74–82 s |
| Engine change (2228 checks) | Sonnet 5.5 | 2228/2228 ×2 | $0.44–0.50 | ~1.5 min |
| | Opus 5.5 | 2228/2228 ×2 | $1.33 | 8–10 min |
| | Fable 5.1 | 2228/2228 ×1 | $7.85 | 14 min |

**prompt-master, review prompt with "only report critical issues"** (11 planted bugs):

| | Haiku 5.5 | Sonnet 5.5 | Opus 5.5 |
|---|---|---|---|
| Without the skill | 3, 3 | 6–7 | 2–7 |
| With the skill | 11, 11 | 10–11 | 10–11 |

**Not measured yet:** Haiku on long agent tasks, a task hard enough to make Sonnet fail, and Fable as the orchestrator. Earlier measurements (September 2026, older models) and retired designs are in [`bench/HISTORY.md`](bench/HISTORY.md).

## Design principles

1. **Every rule cites a source**, with the date it was last checked against the live docs (2026-11-06).
2. **Every claim of benefit is measured against a check that can fail.** "It felt better" is not a result.
3. **What doesn't beat the baseline is cut, in public.** A third skill, `fable-mode`, was measured, found to add cost without benefit, and retired ([`archive/`](archive/)); the first version of `sonnet-lean` was replaced the same way.
4. **Skills cost context.** Keep only what earns its place.

## Repository layout

```
prompt-master/SKILL.md     the request-to-prompt rewriter
sonnet-lean/SKILL.md       set-up guidance for subagents
bench/                     fixtures, hidden tests, runner and graders (see bench/README.md)
  results-2026-11-06/      raw grades and harnesses of the current measurements
  HISTORY.md               earlier measurements and retired designs
docs/sonnet-lean.pdf       a nine-slide introduction to sonnet-lean
archive/fable-mode/        the retired skill and its source-linked reference
```

## Sources & credits

Built on Anthropic's documentation: [Prompting Claude Sonnet 5.5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5-5), [Prompting Claude Opus 5.5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5), [Effort](https://platform.claude.com/docs/en/build-with-claude/effort), [Models overview](https://platform.claude.com/docs/en/about-claude/models/overview), [Pricing](https://platform.claude.com/docs/en/about-claude/pricing), [Claude prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices), and the Claude Code docs on [skills](https://code.claude.com/docs/en/skills) and [subagents](https://code.claude.com/docs/en/sub-agents). Each skill's own Sources section lists the exact pages and sections.

Several verification ideas in the retired `fable-mode` were adopted from [mrtooher/fable-mode](https://github.com/mrtooher/fable-mode); the failable-check standard outlived the skill and is the rule every benchmark here was run under.

## License

[MIT](LICENSE)
