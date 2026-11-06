---
name: sonnet-lean
description: Make Claude Code subagents cost less by configuring them correctly — no useless skill preloads, an explicit effort per agent, a complete brief shape — and by choosing each call's model by evidence (down to Haiku when a check can verify the result, up to Opus only after a failed check). Use when creating or editing a subagent definition (`.claude/agents/*.md`), especially Sonnet ones, when setting `model:`/`effort:`/`skills:` in agent frontmatter or a Workflow script's `agent()` options, when writing an orchestrator's delegation rules in `CLAUDE.md` (which model to call an agent with, when to move one call down to Haiku or up to Opus), when reviewing why Sonnet agents are expensive, or on /sonnet-lean. Set-up-time guidance only: do NOT load it for routine delegation (an orchestrator carrying it while delegating cost 24% more, measured) and do NOT list it in an agent's `skills:` preload (inside a worker it saves nothing and costs tokens, measured three times).
---

# Sonnet Lean — cheaper subagents, set up once

This skill changes how your agents are **configured** — once, when you write or review their definitions and your orchestrator's delegation rules. After that the savings live in the agent files and in `CLAUDE.md`, and the skill isn't needed at run time. Sections 1–5 make an agent cheaper on the model it already has; section 6 decides when a call should use a different model, in either direction. Every rule below is measured in this repository's `bench/` (two to three runs per cell: enough to show a direction, not to size it precisely) or cites Anthropic's documentation.

## 1. Don't preload this skill (or any skill the agent can't act on)

A skill in an agent's `skills:` field is read on every call. Measured on Sonnet 5.5, same task and brief, with and without sonnet-lean preloaded: no quality change, and the preload cost more — about +10% on a real HeroBrowser UI task, +15% on a four-module coding task, +25–33% on a short code review. Sonnet 5.5 already keeps its thinking short and its output compact; telling it to be lean has nothing left to remove.

- In each Sonnet agent's frontmatter, list only skills the agent uses to do its own work (a project's data-shape rules, a domain playbook). Remove `sonnet-lean`, and remove any body paragraph that tells the agent to apply it.
- Remove preloads of skills that no longer exist; a dead name is silently ignored and hides intent.

## 2. Set `effort:` on every Sonnet agent

An agent with no `effort:` runs at the effort of the session that calls it — if your orchestrator runs at `high` or `xhigh`, so does every worker. Set it explicitly per agent:

| Agent's work | `effort:` | Evidence |
|---|---|---|
| Mechanical, well-specified (content tables, asset wiring, renames, CRUD) | `low` | −15–25% cost and ~20% faster than `high` on a coding task, same hidden-test score |
| Default for agentic coding against a clear spec | `medium` | Anthropic's recommended start for Sonnet 5.5 agentic coding; −3% against the inherited default on a real UI task, same score |
| Hard or long (engine determinism, large refactors, open-ended design) | `high` | Sonnet 5.5's API default |
| `xhigh` / `max` | avoid for routine work | Docs: at these levels Sonnet 5.5 starts its own review rounds and subagents; a stop-and-report paragraph cut cost by about a third at `max` |

Two documented risks at `low`/`medium`, none seen in 22 measured runs: on long tasks the agent may stop to check in before finishing, and at `low` it may report a change as done without running a check. If you see either, raise that agent's effort one level before adding prompt text. *(Prompting Sonnet 5.5, "Calibrate effort", "Steer initiative and scope", "Verification on coding tasks")*

Effort levels on the 5.5 models are recalibrated; don't carry Sonnet 5 settings over.

## 3. Brief the agent once, completely

Put this shape into the agent's definition (its body, as the return format it always uses) or into the orchestrator's project instructions once; don't load this skill on every delegation to get it. Measured: an Opus 5.5 orchestrator carrying this skill while delegating to a Sonnet worker cost 24% more than without it ($0.55 against $0.45, same 13/13), because both the orchestrator and the worker did more. Every call to the agent should then be one message that contains:

```text
Task: [one sentence — what and why].
Deliverable: [exact shape — files, schema, list]. Your final message is the return
value: what changed, check results, anything not done. No preamble or recap.
Context: [file paths + line ranges, not pasted content; long material above the ask].
Scope: [explicit boundaries — "every X, not just the first"; what NOT to touch].
Done when: [the command that must pass — tests, typecheck].
```

Sonnet 5.5 follows instructions literally, so state scope explicitly. A second message to fix an under-specified first one costs more than the first one saved. Don't ask for interim status updates; the agent already writes them.

**Not a default:** Anthropic's "don't add features, tests, files, docs or refactors that weren't asked for" paragraph. On our coding task it cost 24% more with nothing to prevent. Add it to a brief only if an agent actually creates files you didn't ask for.

## 4. Batch items that share context

One agent doing three related items used half the tokens of three agents doing one each (69K against 141K, same result, about twice the wall time; measured on Sonnet 5). Fan out only when items are independent and you need them in parallel, and then give every parallel agent the same model, effort and tools so they share the cached prompt prefix.

## 5. API and Workflow notes (5.5 models)

- Workflow: `agent(prompt, {model: 'sonnet', effort: 'medium', schema})` — a schema returns validated data with no prose wrapper.
- API: `output_config: {effort}`; thinking can't be disabled on Sonnet 5.5 (`between_tools` is the lowest setting, at `high` or below); to get less thinking lower effort, since asking the model to think less doesn't reliably work; `max_tokens` covers thinking plus reply; `temperature`/`top_p`/`top_k` and forced tool choice return 400.
- A per-message effort change (beta) keeps the prompt cache; changing the top-level value doesn't.

## 6. Choose the model per task: down when the result is checkable, up only on evidence

Two directions, two different rules. Both are measured; neither assumes a project's design.

**Down a tier: small, well-specified work whose result a check can verify.** Haiku 5.5 matched Sonnet 5.5 on every such task measured, at about a tenth of the cost, but was slower:

| Task (hidden tests) | Haiku 5.5 | Sonnet 5.5 |
|---|---|---|
| Four-module coding task (13) | 13/13 ×4 · $0.02 · ~85 s | 13/13 · $0.19–0.24 · ~60 s |
| Two one-file tasks (17, 10) | full marks ×4 · under $0.01 | — |
| Real project UI module, HeroBrowser (10) | 10/10 ×2 · $0.03 · ~78 s | 10/10 · $0.22 · ~44 s |

End to end: an Opus 5.5 orchestrator told it could route well-specified work down picked Haiku and cost 39% less ($0.28 against $0.46, same 13/13); without that guidance it always picked Sonnet. Not measured: long agent tasks on Haiku (Anthropic notes Haiku 5.5 is more likely to skip a search, stop early or skip a check at `low` in long agent prompts, so use `medium`+), and Haiku past 100K-token prompts, where its price rises 5× (still about a quarter of Sonnet's).

**Up a tier: only after the cheaper run failed a check.** Measured on a real, hard engine change (HeroBrowser commit `298e8358`: move a damage clock without changing RNG order or determinism), graded by the project's own 2228-check test file:

| Agent model | Correct | Cost per run | Time |
|---|---|---|---|
| Sonnet 5.5 | 2228/2228 ×2 | $0.44–0.50 | ~1.5 min |
| Opus 5.5 | 2228/2228 ×2 | $1.33 (~3×) | 8–10 min |
| Fable 5.1 | 2228/2228 ×1 | $7.85 (~17×) | 14 min |

The bigger models were more thorough (they ran the project's balance harness unasked) but not more correct, and slower. "Looks hard" is not evidence; a failed test, typecheck or harness run is. If you want the extra checks a bigger model would run, name them in the brief's "Done when" instead. Anthropic still recommends Opus for the hardest long-horizon work, and none of the tasks measured here was hard enough to make Sonnet fail: escalate when yours does.

**Write the policy into the orchestrator's `CLAUDE.md`**, which is always loaded and costs almost nothing per call (unlike carrying this skill: +24%). Pick the variant that matches your project:

```text
# Flexible: the orchestrator picks the tier per call
Agent models: default to each agent's own model. For a small, well-specified task
whose result a test, typecheck or validator will check, pass `model: 'haiku'`.
Upgrade one call a tier (haiku → sonnet → opus) only after that run failed a check
or got stuck, and say why. Never upgrade because a task looks hard.
```

```text
# Pinned: each agent keeps the model its definition sets
Agent models: call each agent with its own model (leave the Agent tool's `model` unset).
Upgrade one call to `model: 'opus'` only after that agent's run failed a check
(tests, typecheck, harness) or got stuck, and say why. Never upgrade because a task
looks hard. Fable as an agent model only after Opus failed too.
```

## Sources

- Prompting Claude Sonnet 5.5 — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5-5
- Effort — https://platform.claude.com/docs/en/build-with-claude/effort
- Sonnet 5.5 migration guide — https://platform.claude.com/docs/en/models/sonnet-5-5/migration-guide
- Claude Code subagents — https://code.claude.com/docs/en/sub-agents (frontmatter `model`, `effort`, `skills`)
- Measurements — `bench/results-2026-11-06/` in this repository (preload: session B ledger arm, `herobrowser/`, `session-c-preload/`; set-up behaviour: `setup-check/`; model up: `herobrowser-hard/`; model down: Haiku arms, `session-b/graded-delegation.json`; effort sweep; scope line; batching on 2026-09-09).
- Re-verified against the live docs 2026-11-06.
