---
name: prompt-master
description: Rewrite the user's request into the prompt Claude works best with, show the rewrite with one line per change so the user learns, then do the work from the rewrite. FIRST, on every request, scan for instructions Anthropic documents as harmful on current Claude models — severity filters in reviews ("only report critical issues"), "double-check / add a final verification step", step-by-step recipes, "show your reasoning", "think carefully" — and always rewrite when one appears, even in an otherwise complete brief. Also turns "fix it", "get the tests passing", or prompts written in another model's style into a brief with the goal and its reason, checkable done-criteria, explicit scope, the source of truth and any conflict with it, context as @file references, assessment-or-change, and the deliverable's shape. Use on /prompt-master, on vague or underspecified substantial requests, on prompts that read like they were written for a different model, or on human-written prompts before delegating them. Not for briefs Claude writes for its own subagents, or one-line edits.
---

# Prompt Master — write the prompt Claude works best with, then run it

Two facts from Anthropic's documentation drive this skill. First, a well-specified task description **in the first turn** maximizes autonomy and intelligence while minimizing tokens. Second, current Claude models follow instructions **literally**, so a prompt written for another model's habits makes Claude do the wrong thing precisely. Measured on the 5.5 models (2026-11-06), the second fact is the one that pays: "Review this. Only report critical issues." made Opus 5.5 report 2 to 7 of 11 planted bugs; the rewrite made it report 10 or 11.

## 0. Mandatory first step: the strip-list scan

Before anything else, before deciding whether the request is already a complete brief, read the request for every pattern in R8 (§3). **If any one matches, you rewrite. No exceptions.** A complete brief with "double-check everything" is still a worse prompt than the same brief without it, and the user needs to see that line go and read why. Never silently comply with a strip-list instruction and never silently ignore it: show the removal in the Changes block (§5), then execute the cleaned prompt.

In an unattended run (no one to answer, e.g. a headless or scheduled run), the rewrite and its Changes block are the **first thing in your final report**, before any results. This is not optional either; a reader who can't see what changed can't trust the result.

## 1. Decide in ten seconds

After §0: rewrite when the request is vague ("fix", "make it work", "clean up", "get the tests passing" without saying against what), names no done-criteria or scope, or conflicts with the repository. Skip when the request already states goal, done-criteria and scope and §0 found nothing, when it is a one-line edit, or when it is a plain question — answer questions.

**When it pays, measured:** reviews and audits with a severity filter (the biggest win, on every model tested); vague human-written requests (the model follows the spec and leaves your tests alone); prompts carrying a strip-list instruction. **When it doesn't:** briefs Claude writes for its own subagents — they already have this shape, and the rewrite only adds cost.

## 2. Investigate before rewriting

Never rewrite from the words alone. Read what the request points at, in parallel where the reads are independent: the README or spec, the tests, the failing command, the files named. Establish the **source of truth** and its order — a written spec outranks tests, tests outrank the current code, code outranks your assumptions — and note every disagreement between them. Two to six tool calls is normal.

## 3. The rewrite rules

Each rule names the Anthropic guidance it comes from (full URLs under Sources).

- **R1 Goal with its reason.** "I'm working on [larger task] for [who]; they need [what the output enables]." Claude performs better when it knows why. *(Prompting Claude Fable 5, "Give the reason")*
- **R2 Done-criteria that can fail.** A command that exits 0, a file in a given shape, every rule of the spec covered including ones no visible test exercises. Never a feeling. Name the checks that already exist; don't invent a new test suite to satisfy this rule. *(Best practices, self-check anchor)*
- **R3 Scope stated explicitly.** Claude does not generalize an instruction from one item to the rest: say "every section, not just the first", name what is out of scope. If the user wants only the change they named, say so: Sonnet 5.5 tends to add tests, docs and small supporting files nobody asked for. *(Prompting Claude Sonnet 5, "More literal instruction following"; Prompting Claude Sonnet 5.5, "Unrequested additions")*
- **R4 Assessment, plan, or change.** If the user is describing a problem, thinking out loud, or asking for ideas, options or a plan, the deliverable is that, and the model stops there; if they want a change, say so. Left unsaid, Claude may fix what it was only asked to look at, or start building when only ideas were wanted. *(Prompting Claude Fable 5, "State the boundaries"; Prompting Claude Sonnet 5.5, "Open-ended requests")*
- **R5 Context as facts, not adjectives.** Paths and line ranges, `@file` references in Claude Code, the exact error text. Long material at the top, the ask at the end; for long documents, ask for relevant quotes first. *(Best practices, "Long context prompting")*
- **R6 Source of truth and conflicts.** Name it. When a test contradicts the spec, follow the spec and surface the conflict; do not edit the lower-ranked artifact to make the conflict disappear unless asked. *(Best practices, "Avoid focusing on passing tests")*
- **R7 Deliverable shape.** Exactly what the final answer looks like: a diff, a list with confidence and severity per item, a file, three sentences.
- **R8 Strip what hurts on current Claude models.** (Scanned first, per §0.)
  - *"Only report critical / high-severity issues", "be conservative", "don't nitpick"* in a review → Claude follows it literally and drops real bugs; recall falls while bug-finding is unchanged. Replace with: **report every issue you find, including uncertain and low-severity ones, each with a confidence and an estimated severity; filtering happens afterwards.** Opus 5.5 obeys the filter *more* literally than Opus 5 did, so this matters more now, not less. *(Prompting Claude Sonnet 5 and Opus 5, "Code review"; measured below)*
  - *"Double-check your work", "add a final verification step", "re-verify before responding", "use a subagent to verify"* → over-verification: more tokens and time, no quality gain. Remove. Measured on Opus 5.5: +19% to +25% cost and up to +52% time for an identical result. *(Prompting Claude Opus 5, "Task scope and over-verification"; Prompting Claude Sonnet 5.5, "Thoroughness at `xhigh` and `max` effort")*
  - *Enumerated step-by-step recipes* for a capable model → worse than goal plus constraints; prefer "think thoroughly about X, constraints are Y". *(Prompting Claude Fable 5, "Refactor existing prompts")*
  - *"Show your reasoning", "explain your thinking in the answer", "write out your reasoning before answering"* → invites the `reasoning_extraction` refusal on Fable 5.1, Opus 5.5 and Sonnet 5.5. Ask for the conclusion, its evidence, or a short explanation of the answer instead. *(Prompting Claude Sonnet 5.5 and Opus 5.5, "Safeguard refusals")*
  - *"Think carefully before answering", "think step by step"* → effort is the control for how much the model thinks; on Opus 5.5 removing such a line made replies start sooner with no clear quality loss. Drop it. Also drop role-play preambles and all-caps emphasis so the real instructions stand out. *(Prompting Claude Opus 5.5, "Thinking instructions in chat system prompts")*
- **R9 Ask once, or assume.** If different readings would lead to materially different work, ask all questions in one batch, at most three, then stop. Unattended, or when the difference is minor: pick the reading the spec and code most directly support and record it as a numbered assumption.

## 4. Claude Code mechanics check

While rewriting, note anything the harness offers that the user didn't use: plan mode for multi-file changes; `@file` instead of describing a file; a model and effort matched to the task (see `sonnet-lean`: Haiku 5.5 first for well-specified, checkable work, Sonnet 5.5 at `low`/`medium` next, Opus 5.5 at its `medium` default for long-horizon work); a subagent when work fans out across independent items; an existing skill or `CLAUDE.md` convention that applies. One line each, only when relevant.

## 5. Show the rewrite

```text
Original: <the request, verbatim>

Rewritten prompt:
Goal: …            (R1)
Done when: …       (R2)
Scope: … / Out of scope: …   (R3)
Mode: assessment | plan | change    (R4)
Context: …         (R5)
Source of truth: …; conflicts: …   (R6)
Deliverable: …     (R7)
Assumptions: 1. … (R9)

Changes: one line each — what changed, why, which rule.
```

Interactive: show this before starting, then execute unless the user asked for the prompt only ("just rewrite", "prompt only", `/prompt-master --only`). Unattended: this block opens the final report (§0).

## 6. Execute the rewritten prompt, not the original

Work against **Done when**; run every check it names and look at the output. Report against the rewrite: each done-criterion with its evidence, every conflict and how it was resolved, every assumption restated, anything unmet stated plainly. Things noticed but not asked for go in one "follow-ups" line, not in the change.

## When NOT to apply

Complete briefs with no strip-list match, briefs Claude writes for its own subagents, one-line edits, questions. Rewriting a prompt that already is one wastes the tokens this skill exists to save.

## Measured (method and raw numbers in `bench/` and `bench/results-2026-11-06/`)

**2026-11-06, the 5.5 models, Claude Code 2.1.319** (two sessions' runs combined; two to four runs per cell):

- **The review trap (R8, first bullet).** "Review lib/orders.js. Only report critical issues." against 11 planted bugs. Bugs reported without → with the skill: Sonnet 5.5 6–7 → 10–11 (4 runs each); Opus 5.5 2–7 → 10–11 (4 runs each); Haiku 5.5 3 → 11 in the run where the skill fired, 4 in the run where Haiku ignored it. Extra cost: about 3–7 cents per review.
- **Vague prompt (R1, R2, R6, R9).** "Tests are failing in this project. Get them passing." with a visible test that contradicts the spec. Same 13/13 hidden tests either way. Without the skill, 5 of 6 Sonnet 5.5 and Opus 5.5 runs rewrote the test to make it pass; with it, 0 of 6. Cost: Sonnet 5.5 +8–12%, Opus 5.5 flat.
- **The over-verification trap (R8, second bullet), Opus 5.5.** The instruction costs +19–25%. Across four skill runs (two before §0 was moved to the top, two after) the skill removed it in 2 of 4; one of those saved 26%, the other cost the same as the raw runs. **Treat this bullet as documented, not as a measured saving**, and the trigger on otherwise complete briefs as still unreliable.
- **Re-test after moving the strip-list scan to §0 (same day, 8 runs).** Review trap: Haiku 5.5 11/11 in both runs (before: 11 and 4, one run ignored the skill), Sonnet 5.5 11 and 10. Vague prompt on Sonnet 5.5: test left alone in 2 of 2, cost $0.18, the same as without the skill; the rewrite was still not printed at the top of the unattended report (0 of 2), a known gap.

**2026-09-09, Sonnet 5 and Opus 5 (historical):** review trap 2–4 → 9–10 of 11 on Sonnet 5, 10 → 11 on Opus 5; same test-integrity difference on vague prompts; on the double-check trap the skill removed the instruction in 1 of 2 runs and did not save money.

**Not measured:** the interactive question round (R9), the mechanics check (§4), the R3/R4 additions from the Sonnet 5.5 page, anything beyond one review file and three coding tasks.

## Sources

- Prompting Claude Sonnet 5.5 — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5-5 ("Steer initiative and scope", "Unrequested additions", "Open-ended requests", "Safeguard refusals")
- Prompting Claude Opus 5.5 — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5-5 ("Calibrate effort", "Safeguard refusals", "Thinking instructions in chat system prompts")
- Prompting Claude Sonnet 5 — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5 ("More literal instruction following", "Code review harnesses")
- Prompting Claude Opus 5 — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5 ("Task scope and over-verification", code review)
- Prompting Claude Fable 5 — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5 ("Give the reason, not only the request", "State the boundaries", "Recommended scaffolding changes")
- Claude prompting best practices — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices ("Be clear and direct", "Long context prompting", "Avoid focusing on passing tests and hardcoding")
- Re-verified against the live docs 2026-11-06. The 5.5 pages say existing Sonnet 5 and Opus 5 prompts "should perform well without changes", so the Sonnet 5 / Opus 5 guidance above still applies alongside the 5.5 additions.
