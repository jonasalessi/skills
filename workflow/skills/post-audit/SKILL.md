---
name: post-audit
# ADAPT description: name the default branch, the project, the changelog file
# and the gate. Example: "Audit the combined state of main after a batch of
# merges and before a release of <project>. ... the docs and CHANGELOG ledger,
# ..., and that make check and hosted CI are green ...".
description: Audit the combined state of the default branch after a batch of merges and before a release. Checks provenance of every commit in the range, cross-change interactions, the docs and changelog ledger, dependency advisories, and that the project's gate and hosted CI are green on the exact SHA. Use after resolving more than three tickets, or as the gate before release.
metadata:
  author: Jonas Alessi
  reference: Skills release, security-audit and pipeline from the same set
---

# Post-audit

Audit the final tree, not the sum of optimistic PR summaries. This is the
last gate before a release. It does not release.

## Phase 0: freeze the range

<!-- ADAPT default-branch: replace `<default>` with the branch name. Once the
     project has a tag, simplify `BASE_SHA` to the last tag with the root
     commit as fallback: `BASE_SHA=$(git describe --tags --abbrev=0
     2>/dev/null || git rev-list --max-parents=0 HEAD)`. -->
```sh
git switch <default> && git pull --ff-only
git status --short --branch
BASE_SHA=${LAST_CLEAN_AUDIT_SHA:-$(git describe --tags --abbrev=0 2>/dev/null || echo "${START_SHA:-$(git rev-list --max-parents=0 HEAD)}")}
HEAD_SHA=$(git rev-parse HEAD)
RANGE="$BASE_SHA..$HEAD_SHA"
```

<!-- ADAPT default-branch: shorten to match the `BASE_SHA` line above.
     Example: "For an incremental audit after a batch, `BASE_SHA` is the last
     SHA a clean post-audit recorded. If `HEAD` moves during the audit,
     inspect the new commits and rerun the affected phases." -->
`LAST_CLEAN_AUDIT_SHA` is the SHA a clean post-audit recorded earlier in
the conversation, when there is one; then the last tag; then the SHA the
pipeline recorded at the start of the run when the project has no tag
yet. The root commit is the last resort, and the report then says the
range is unbounded. If `HEAD` moves during the audit, inspect the new
commits and rerun the affected phases.

<!-- ADAPT release-mechanism: keep this paragraph only when the release
     mechanism publishes on every push to the default branch. Delete it
     otherwise. -->
**Pre-merge mode**, for a project whose release mechanism publishes on
every push to the default branch: run this phase inside the scratch
worktree the pipeline built, with that branch's head as `HEAD_SHA` and the
default branch as `BASE_SHA`; in Phase 1 read "issue closed" as "PR open
and linked to the issue"; in Phase 5 the hosted checks on each PR head
plus the local gate on the scratch tree stand in for checks on `HEAD_SHA`,
and the report says so.

## Phase 1: provenance

```sh
git log --first-parent --format='%h %an %s' "$RANGE"
git log --no-merges --format='%h %an %s' "$RANGE"
git diff --stat "$RANGE"
git diff --name-status "$RANGE"
git diff --check "$RANGE"
```

<!-- ADAPT merge-strategy: keep only the sentence for the project's merge
     strategy and name the commit format. Example: "Every PR lands with a
     merge commit, so the first-parent log lists the PRs and any direct push
     to `main`. Map each one to its PR and issue (`gh pr list --state merged
     --search "<sha>"`), and check that no merge or direct commit escaped an
     audit, every referenced issue is closed, and every non-merge commit
     message reads `<type>: <description>`." -->
With merge commits the first-parent log lists the PRs and any direct push;
with squash merges every commit is one PR, and with rebase merges a PR may
span several. Map each one to its PR and issue
(`gh api repos/{owner}/{repo}/commits/<sha>/pulls`, which answers for
merge, squash and rebase merges alike), and check that
no merge or direct commit escaped an audit, every referenced issue is
closed, and every commit message follows the project's convention.

## Phase 2: composition sweep

Read the merged code around the hunks, not the hunks alone:

   <!-- ADAPT contracts: name the contract check: the command to run, the
        fixtures and the document to compare with. Example: "run `bin/tool
        check --all --explain --format json` on `testdata/` and compare the
        fields with `docs/editor-integration.md`". Without a contract keep the
        generic sentence. -->
1. Two changes that each keep a contract may break it together: exercise
   every machine-readable output, public API or schema the project
   documents against its doc.
   <!-- ADAPT rules: name the parallel implementations this project has.
        Example: "A rule that lives in two analyzers now disagrees: compare
        the same construct across `internal/analyze/*` when the range touched
        more than one language." -->
2. A rule that lives in two places now disagrees: compare parallel
   implementations of the same behaviour when the range touched more than
   one.
   <!-- ADAPT stack: name the project's own configuration file and the
        commands it must pass. Example: "the repository's own hand-tuned
        `tool.config.yaml` must still validate without warnings and pass
        `bin/tool check` (CI runs both)". -->
3. Config composition: a new field plus a changed default may change what
   an existing configuration means; the project's own configuration and
   examples must still validate and pass.
   <!-- ADAPT stack: name the helper concerns and code roots of this project.
        Example: "duplicated normalisation, path handling or error wrapping in
        `cmd/` and `internal/`". -->
4. Helper drift: duplicated normalisation, path handling, retry, error or
   permission logic across modules.
5. Test masking: a helper or fixture from one change lets another change's
   test pass without exercising production code.

## Phase 3: security sweep

<!-- ADAPT security-surfaces: use the stack's term for a dependency source
     directive (example: "`replace` directives"), name where process execution
     is allowed (example: "outside `internal/git`"), and replace the tool list
     with the one advisory command in a `sh` block (example: `go run
     golang.org/x/vuln/cmd/govulncheck@latest ./...`). -->
Inspect the range for executable bits, symlinks, binaries, encoded blobs,
new dependencies, dependencies from git or path sources, workflow permission
changes and process execution in new places. Run the advisory tool of the
stack (`govulncheck`, `npm audit`, `cargo audit`, `pip-audit`,
`bundler-audit`, OWASP dependency-check for Gradle and Maven, or the
stack's equivalent); when none exists, the report says so.

<!-- ADAPT security-surfaces: list the packages and files whose change
     triggers `security-audit` in this project. Example: "when it touched
     `internal/git`, `internal/githook`, config loading, path resolution or a
     workflow". -->
Run `security-audit` over the range when it touched authentication,
authorization, file or path handling, subprocesses, parsers of untrusted
input, hooks, or a workflow. Any credible malicious behaviour blocks the
release.

## Phase 4: docs and release ledger

<!-- ADAPT docs: list the user-visible surfaces this project has and the docs
     kept by hand, then keep only the sentence for the project's changelog
     form and name the file. Example: "commands, flags, config fields,
     formats, languages, exit codes, the hook. For each one confirm the
     README, the config template comments, `docs/languages.md` and
     `docs/editor-integration.md` still describe the current behaviour, and
     that `CHANGELOG.md` has its line under `## [Unreleased]` in the right
     category." -->
Build the list of user-visible surfaces from the diff, not from PR prose:
commands, flags, endpoints, config fields, formats, defaults, exit codes,
install steps. For each one confirm the README, the reference docs and any
contract doc still describe the current behaviour. With a hand-maintained
changelog, confirm each surface has its line under `Unreleased` in the
right category; an entry that landed under an already released heading is
a finding. With a tool-generated changelog or none, confirm each commit
subject classifies its impact when the convention carries one; with a
free-form convention, note that the maintainer names the version.

<!-- ADAPT changelog: keep the version rule that matches the project's
     changelog form and drop the others. With a hand-maintained changelog the
     first two sentences suffice. -->
Recommend the version from the ledger: entries under Fixed (or Security)
only give a patch; any entry under Added, Changed or Removed gives a
minor; any entry marked **Breaking** gives a major, or a minor while the
major is still 0. From commit subjects, classify the same way. When the
convention carries no impact, the recommendation is "maintainer names the
version". Name the single entry that forces the recommendation.

## Phase 5: gates on the exact SHA

<!-- ADAPT gate: replace `<gate>` with the gate command and `<default>` with
     the branch name. Keep the `gh run list` line for GitHub Actions, the `gh
     api` line for another checks app, or neither without hosted CI. -->
```sh
<gate>
gh run list --branch <default> --commit "$HEAD_SHA" --json name,conclusion,url   # GitHub Actions
gh api "repos/{owner}/{repo}/commits/$HEAD_SHA/check-runs" --jq '.check_runs[] | "\(.name) \(.conclusion)"'   # any checks app
```

<!-- ADAPT ci: drop the last sentence when the project has hosted CI, and drop
     the full-matrix sentence when the merge gate already runs everything. -->
Both must be green on `HEAD_SHA` itself. A green run on a PR head does not
count for the merged tree. Never call a pending, skipped or cancelled job
green. A release candidate needs the full matrix the project runs, not only
the fast subset a merge gates on. A project without hosted CI has only the
local gate; the report says so instead of claiming hosted evidence.

## Phase 6: fix loop

Order findings by security and data loss, then correctness, then docs and
tests. Fix each through `resolve` as its own ticket and PR, then rerun this
audit over the extended range. Nothing is tagged while a blocking finding
is open.

## Output

<!-- ADAPT gate: replace `<gate>` with the gate command, "hosted checks" with
     the workflow name and "advisory tool" with its name. Example: "Gates:
     make check <result>; ci <conclusion> <url>" and "<sweep result,
     govulncheck result>". -->
```markdown
## Post-audit: <BASE_SHA>..<HEAD_SHA>

Commits audited: <n> (<#PR -> #issue> ...)
Gates: <gate> <result>; hosted checks <conclusion> <url>

### Findings
- [SEVERITY] path:line - impact and required fix (severities as in `pr-audit`)

### Security
- <sweep result, advisory tool result>

### Docs and changelog ledger
- <complete | stale: file and surface>
- Version recommendation: patch | minor | major, forced by <entry> | maintainer names the version

Release readiness: ready | blocked by <findings>
```

When readiness is `ready`, record `LAST_CLEAN_AUDIT_SHA=<HEAD_SHA>` for
later audits in the same conversation and for the release.
