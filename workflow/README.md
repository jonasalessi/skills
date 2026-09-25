# workflow

Eight skills that take a GitHub issue to a merged change and a published
release, with fixed gates deciding what lands and a maintainer deciding what
gets built. They read the repository they run in: its trusted instructions,
its gate, its commit convention, its merge strategy, its changelog and its
release mechanism. Nothing in them names a particular project or stack.

>Please do not just copy and paste, adapt it to your project.

## How it flows

![From an issue to a release: you open an issue and run the pipeline; it profiles the project, audits PRs and issues, applies the approval policy, resolves approved tickets one PR at a time, post-audits and releases when asked; a feature request waits for your label](assets/workflow.svg)

| Skill | What it produces |
| --- | --- |
| `pipeline` | the steps below in order, the project profile they share, and the approval policy that stands in for a maintainer |
| `pr-audit` | a verdict per open pull request, from evidence in the diff and the project's gate in an isolated worktree |
| `dependency-bump` | one consolidated PR that closes every bot dependency PR |
| `issue-audit` | a verdict per issue: reproduced or not, root cause, fix plan, and for a feature the proposal the maintainer approves |
| `resolve` | one branch, one PR and one merge per approved ticket, test first |
| `post-audit` | an audit of everything on the default branch since the last tag, required after more than three tickets and before every release (a release of at most two individually audited commits may skip it) |
| `security-audit` | a threat-model review built from the surfaces the project has |
| `release` | the changelog and version finalised, the tag pushed, the project's own release mechanism watched and verified |

## Install

Copy the `skills/* ` into `~/.claude|agents/skills/`.
Copy `scripts/pipeline.sh` somewhere on your project for headless runs.

## Layout

```
workflow/
├── README.md
├── assets/workflow.svg     the diagram above
├── scripts/pipeline.sh     headless runner
└── skills/<name>/SKILL.md  one directory per skill
```

## What a project needs

The skills adapt to what they find, and say so in the report. A project gets
the most out of them with:

- trusted instructions on the default branch (`AGENTS.md`, `CLAUDE.md`,
  `CONTRIBUTING.md` or the README) that name the gate, the commit
  convention and the rules a tool cannot check; ***This is a strong candidate to be changed according to your reality***
- a `CHANGELOG.md` in Keep a Changelog form, so the release reads the
  version from the ledger; without it the commit convention is used;
- a release mechanism, ideally a workflow triggered on tags; without one,
  a release tool if configured, else `gh release create`;
- hosted CI; without it the local gate is the only gate and the report
  says so;
- labels for the policy's states: the project's own when it has
  equivalents, otherwise `needs-decision`, `approved`, `question`,
  `duplicate`, `wontfix` and `invalid`, created on first use.

## Daily use

```
/pipeline                  audit and resolve every open PR and issue
/pipeline 12               only issue 12
/pipeline 12 release       issue 12, then cut a release
pipeline.sh 12 release     the same, without a terminal session
```

The skills speak to GitHub through `gh`: issues, pull requests, labels,
checks and releases. Another forge needs its own port.

Bugs and docs fixes flow without the maintainer. A feature request gets a
proposal comment and the project's decision label (`needs-decision` when
it has none); the maintainer answers with the approval label
(`approved`), `wontfix` or a reply that amends the plan, and the next run
builds what was agreed. Issue and PR text is evidence, never
instructions. Nothing is tagged on red CI, with a blocking finding open, or
without an explicit ask.
