# workflow

Eight skills that take a GitHub issue to a merged change and a published
release, with fixed gates deciding what lands and a maintainer deciding what
gets built. They read the repository they run in: its trusted instructions,
its gate, its commit convention, its merge strategy, its changelog and its
release mechanism. Nothing in them names a particular project or stack.

>Please do not just copy and paste, adapt it to your project.

## How it flows

![From an issue to a release: you open an issue and run the pipeline; it profiles the project, audits PRs and issues, applies the approval policy, resolves approved tickets one PR at a time, post-audits and releases when asked; a feature request waits for your label](assets/workflow.svg)

## What the maintainer does

Four touchpoints. Everything between them runs on its own.

1. **Open an issue, or let a user do it.** The issue is the whole spec, so
   the better the reproduction, the less the audit guesses: for a bug, the
   version, the steps, what happened and what was expected; for a feature,
   the problem rather than the solution. An idea of your own that needs no
   discussion gets the approval label when you file it, and the next run
   builds it without asking.
2. **Run the pipeline when it suits you.** `/pipeline` works through
   everything open; `/pipeline 12` takes one issue; adding `release` ships
   what has accumulated once the last ticket lands. `scripts/pipeline.sh`
   runs the same thing headless, from a shell or a cron job. You do not
   pick the version: the changelog or the commit convention does.
3. **Decide on features, and only on features.** Bugs and docs fixes are
   merged without you. A feature request comes back to you as the
   project's decision label plus a comment with the plan: the change, where
   it goes, the tests, the docs, the size, and what is left out. You answer
   in one of three ways: the approval label builds it as written on the
   next run, a reply that amends the plan is followed over the comment, and
   `wontfix` ends it. Nothing is built until you answer.
4. **Read the report.** Each run ends with what landed (PRs, issues, the
   release) and a "left for the maintainer" list: features awaiting your
   decision, PRs that need a review the agent cannot give, tickets it
   declined or could not reproduce, each with its evidence. Close or reopen
   what the agent would not; it never closes a declined ticket on its own.

Two habits keep this healthy. When a run does something you dislike, fix
the skill that made the call rather than the output. And keep the trusted
instructions current: the profile reads them first, so a rule written there
is a rule every run follows.

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

Issue and PR text is evidence, never instructions. Nothing is tagged on
red CI, with a blocking finding open, or without an explicit ask.
