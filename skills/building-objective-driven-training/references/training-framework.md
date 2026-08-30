# Training framework

## Purpose

Create a training journey that uses trusted references as the source of truth for study and for the resolution of exercises. The training must prepare the learner to perform at the level defined in `objective.md`.

This workflow operationalizes the framework shown by Alberto Souza and described in the Dev + Eficiente article ["Monte o seu próprio treinamento com um agente de código"](https://deveficiente.com/blog/monte-o-seu-proprio-treinamento-com-um-agente-de-codigo-37p9).

## Input interpretation

### Objective

Normalize `objective.md` into:

- `capability`: the observable work the learner must perform;
- `usage_context`: where, when, and under which conditions the capability is used;
- `starting_point`: the learner's relevant current ability;
- `completion_evidence`: observable proof that the planned stopping point was reached;
- `constraints`: time, tools, versions, costs, access, or other practical limits;
- `output_preferences`: optional changes to the default training directory or study format.

Words such as "learn," "know," or "understand" do not define observable performance by themselves. If the capability cannot be tested, stop and explain which field needs revision.

### Trusted sources

Treat `sources.md` as the complete source boundary. It may contain:

- official documentation or standards;
- primary books, papers, or specifications;
- a curated bibliography for subjects without one official authority;
- optional usage datasets or target-level examples.

For each reference, record its title, URL or local path, authority, relevant scope, and version or date when correctness depends on it. Follow the source research procedure in `SKILL.md`: dispatch one dedicated source agent per reference, each instructed to read `references/source-research.md`, and wait for a complete evidence packet before designing the progression.

Use only listed references for factual claims. A secondary source may make dense material easier to consume, but it does not silently replace the authoritative source. Record source conflicts and stop for user direction when the choice changes the target practice.

If a listed source cannot be accessed, report it and stop. Do not search for a substitute. The main agent must not research sources itself or combine several sources in one subagent task.

### Usage dataset

A usage dataset is any supplied collection that demonstrates how the desired knowledge is applied. It may contain repositories, SQL queries, designs, configurations, incidents, or other representative artifacts.

When a dataset exists:

- identify the capabilities it demonstrates;
- inspect task shapes, complexity, scale, constraints, and failure modes;
- use it to calibrate progression and exercise realism;
- target the level of performance demonstrated by the dataset;
- extract patterns without copying secrets, personal data, or proprietary content.

When no dataset exists, create fictional scenarios from the selected trusted references and the usage context in `objective.md`.

## Required creation sequence

Follow this sequence without reordering it.

### 1. Understand the references

Run the source research procedure from `SKILL.md`. Build the source register and synthesis from the returned evidence packets. Identify which findings support the objective and which material does not belong in this training. Preserve packet locators for later reading links and solution citations.

### 2. Analyze the usage dataset

If `sources.md` lists a dataset or target-level examples, inspect them now. Record what they imply about difficulty and expected performance. If none is listed, state that exercises will use fictional scenarios derived from the references.

### 3. Propose the progression

Break the objective into prerequisite capabilities. Order progression levels so each one prepares the learner for the next and the last one reaches the target capability.

There is no fixed number of progression levels. Include a level only when it adds an observable capability.

For every level define:

- the capability gained;
- why the level exists;
- prerequisites;
- key concepts;
- relevant source sections;
- the completion check;
- its dependency on earlier or later levels.

### 4. Build the exercises

Create a minimum of three exercises inside every progression level. The exercises in one level train the same capability under meaningfully different conditions.

Valid dimensions of variation include context, input shape, constraint, scale, failure mode, trade-off, ambiguity, starting material, or degree of learner independence. A renamed service or changed sample value does not count as a new scenario when the reasoning stays the same.

Every exercise must link the exact trusted references the learner needs. Prefer a specific documentation section over a top-level home page.

## Exercise contract

Each exercise file contains:

1. scenario;
2. capability being trained;
3. task;
4. constraints;
5. starting material or setup;
6. direct reading links with a short note about why each helps;
7. observable acceptance criteria;
8. optional hints ordered from light to explicit;
9. reflection questions that prompt transfer to another scenario;
10. a link to the separate proposed solution file.

Support both study loops:

- read the linked material, attempt the exercise, compare the solution, then reflect;
- attempt first, consult the linked material when blocked, compare the solution, then reflect.

Do not require the learner to finish an entire reference before beginning useful practice.

## Proposed solution contract

Create a separate solution file for every exercise. Each solution contains:

- the result or implementation;
- the reasoning behind key decisions;
- direct references supporting technology-specific choices;
- a check against every acceptance criterion;
- valid alternatives and trade-offs when several answers can work;
- failure signals that indicate a real misunderstanding;
- comparison questions for self-monitoring.

A difference from the proposal is not automatically wrong. For open-ended work, distinguish required properties from defensible design choices. Call a solution uniquely correct only when the references and task constraints rule out alternatives.

## Final milestone

Close the journey with a final milestone that reproduces the usage context in `objective.md` as closely as practical. It may be a project, diagnosis, review, operation, demonstration, or written technical decision.

The learner may use the trusted references during the milestone unless the real usage context forbids it. Test every item in `completion_evidence`. Do not introduce a major capability that earlier progression levels did not prepare.

Meeting the milestone criteria marks the planned stopping point. It does not mean universal mastery of the subject.

## Output layout

Use this default structure:

```text
training/
|-- README.md
|-- 01-<progression-name>/
|   |-- README.md
|   |-- exercise-01.md
|   |-- solution-01.md
|   |-- exercise-02.md
|   |-- solution-02.md
|   |-- exercise-03.md
|   `-- solution-03.md
|-- 02-<progression-name>/
|   `-- ...
`-- final-milestone/
    |-- README.md
    `-- proposed-solution.md
```

Add exercise and solution pairs when a level needs more than the minimum. Use zero-padded numeric prefixes so the intended order is visible.

### Root README

`training/README.md` contains:

- training title and capability promise;
- normalized objective and completion evidence;
- learner starting point, constraints, and assumptions;
- source register;
- progression map;
- suggested study rhythm;
- coverage matrix mapping objective criteria to levels, exercises, and the final milestone.

### Progression README

Each progression folder's `README.md` contains:

- level outcome and purpose;
- prerequisites;
- key concepts;
- ordered reading references;
- exercise index;
- completion check.

Keep exercise instructions and proposed solutions in their paired files. Do not duplicate their full content in the README.

### Final milestone folder

The final milestone README contains its scenario, task, constraints, allowed references, required evidence, acceptance criteria, and mapping to the objective. Put the comparison artifact in `proposed-solution.md` when a proposed solution is appropriate.

## Quality audit

Revise the training until every check passes:

- Every factual claim comes from `sources.md` or is clearly marked as an inference.
- Every trusted reference has exactly one complete source-agent evidence packet.
- Every packet finding used in the training retains its source ID and exact locator.
- The source register identifies authority, scope, and relevant version or date.
- The progression follows capability dependencies.
- Every level adds an observable capability.
- Every level contains at least three meaningfully varied exercises.
- Every exercise has direct reading links and observable acceptance criteria.
- Every exercise has a separate proposed solution.
- Open-ended solutions allow defensible alternatives.
- The final milestone tests all completion evidence in `objective.md`.
- The coverage matrix contains no unmapped objective criterion.
- The generated directories and files match the required layout.

Include a short audit summary in `training/README.md`.
