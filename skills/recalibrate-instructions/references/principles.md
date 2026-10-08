# Audit principles

Each principle has a smell to look for, the reason it matters, and a before/after example.

## 1. Descriptions trigger on the task, not the topic

**Smell:** a skill description lists broad domains ("databases, queries, models, persistence") so it fires on any adjacent work.

**Why:** the model reads descriptions to decide whether to load a skill. Broad descriptions pull the skill into unrelated tasks and crowd out the ones that fit.

**Before:** "Create and validate Postgres schema migrations. Use when working with databases, queries, models, or persistence."
**After:** "Create and validate Postgres schema migrations. Use when adding or changing a migration, or reviewing its rollout."

Descriptions should be as short as possible while making it clear when the skill applies.

## 2. Root documents are routers

**Smell:** a `SKILL.md` or `AGENTS.md` inlines full reference material, long checklists, or copied documentation.

**Why:** everything in the root loads every time. Bulk raises compaction pressure and pushes irrelevant guidance into context.

**Fix:** keep the root short enough to navigate. Move detail into `references/` files and point to them by purpose.

## 3. Conditional references, not mandatory reads

**Smell:** "Before every edit, read X, Y, and Z."

**Why:** unconditional reads waste context and slow every task, including the ones those files do not touch.

**Before:** "Before every edit, read architecture.md, database.md, and deployment.md."
**After:** "Use architecture.md for service boundaries, database.md for schema changes, and deployment.md when preparing a deployment."

## 4. Fewer recipes, more intent

**Smell:** numbered itineraries covering every step of a routine task, exact phrasing to use, or instructions the model would follow anyway.

**Why:** step-by-step recipes were written for models that needed the handholding. A capable model handles nuance and the recipe now overconstrains it.

**Fix:** state the goal and the constraints that matter. Keep steps only where the order is non-obvious or project-specific.

## 5. Drop encouragement and nagging

**Smell:** "Always remember to run tests.", "Be thorough.", "Make sure you verify.", repeated emphasis in capitals.

**Why:** frontier models test, verify, and check their work without prompting. The nagging spends tokens on behavior that already happens.

**Fix:** delete it. If a specific verification step is project-specific, state it once as a fact ("Run `make check` before opening a PR").

## 6. Grant permission for safe workflows

**Smell:** cautionary language everywhere, no statement of what is safe to do without asking.

**Why:** heavy caution written for a less aligned model now makes a capable one stop and ask at every step. Trust its judgment on what is safe and say so explicitly.

**Example:** "The local tests use disposable fixtures and have no production access. Run them, fix failures caused by the requested change, and rerun affected tests without asking for approval at each step."

Keep genuine boundaries (production data, destructive commands, external side effects). Remove blanket warnings.

## 7. Define completion, not stopping points

**Smell:** instructions that invite a pause after the first phase ("implement, then report back"), or no definition of done at all.

**Why:** a capable model may stop after the first implementation step when the request is ambiguous about where the task ends.

**Fix:** state the full workflow in one request: implement, inspect, debug, verify. Specify the exploration scope and the stopping criteria up front. Avoid checkpoints that read as "stop here".

## 8. Consider who reads the file

**Smell:** one instruction set shared by tools that run models of very different capability.

**Why:** guidance that helps a weaker model may overconstrain a stronger one.

**Fix:** if the repo is used by several agents, keep shared facts in `AGENTS.md` and put model-specific tuning in that tool's own file. Note any instruction that exists only for a weaker model.

## Quick checklist

For each instruction ask:

- Would the model do this anyway? Remove.
- Is this loaded every time but needed rarely? Move to a reference and link conditionally.
- Does it constrain how rather than what? Rewrite as intent.
- Does it warn without granting? Add the permission for the safe case.
- Does it describe where to stop? Replace with what done looks like.
- Is its reason unknown? Flag, do not delete.
