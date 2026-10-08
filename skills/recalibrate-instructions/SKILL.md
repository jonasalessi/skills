---
name: recalibrate-instructions
description: >
  Audit and rewrite project skills, AGENTS.md, and CLAUDE.md for frontier models,
  removing scaffolding written for weaker models. Use when asked to recalibrate,
  audit, or modernize agent instructions.
disable-model-invocation: true
argument-hint: "[optional: path to a skill, AGENTS.md, or CLAUDE.md]"
---

# Recalibrate Instructions

Instructions accumulate. Rules written to constrain a weaker model now waste context, overconstrain a stronger one, or make it stop early. Revisit each instruction and ask whether it is still needed.

Source: [Rethinking skills and prompts for GPT-6 Astra](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra). The principles apply to any frontier model.

## Scope

With an argument, audit only that file or skill directory. Without one, audit the project's `AGENTS.md`, `CLAUDE.md`, `.claude/rules/`, and every `SKILL.md` under `.claude/skills/`, `.agents/skills/`, and `skills/`. Skip global user files outside the project unless explicitly named.

## Process

1. Read each target fully, including files it references.
2. Score every instruction against `references/principles.md`. Record the finding, the principle it violates, and the proposed rewrite.
3. Present findings grouped by file before changing anything. Mark each as **remove**, **rewrite**, or **keep**.
4. Apply the approved changes. Preserve intent, formatting conventions, and anything the audit could not classify with confidence.
5. Report using `references/report-format.md`.

## Boundaries

- Never delete a rule whose reason is unknown; flag it and ask.
- Do not shorten for its own sake. Remove instructions only when the model already does the behavior unprompted or the rule no longer holds.
- Keep instructions that encode project facts (paths, commands, conventions). Those are knowledge, not scaffolding.
