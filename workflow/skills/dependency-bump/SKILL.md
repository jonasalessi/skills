---
name: dependency-bump
description: Land bot-authored dependency pull requests (Dependabot, Renovate) as one consolidated update. Verifies each bump comes from the public registry, updates the dependencies together with the project's package manager, runs the project's gate once, and opens one PR that closes every bot PR. Use only for bot PRs that touch manifests, lockfiles or workflow action pins; anything else goes to pr-audit.
metadata:
  author: Jonas Alessi
  reference: Skills pr-audit and pipeline from the same set
---

# Dependency bump

Several bot PRs are one unit of work. Consolidate them, verify the whole set
with one gate, and land one change.

## Step 1: inventory

```sh
gh pr list --state open --json number,title,author,headRefName,files,url \
  --jq '.[] | select(.author.is_bot or (.author.login | test("dependabot|renovate")))'
```

A PR qualifies when its files are only the manifest, the lockfile or a
workflow file, and the title is a plain bump. Anything else is handed to
`pr-audit`. Two bumps need a closer look before they qualify:

- A dependency the trusted instructions pin or single out only lands when
  the checks those instructions name pass on it; say so in the report.
- A major version, or a package whose name or path changed: hand it to
  `pr-audit`.

## Step 2: supply-chain floor

For each bumped dependency confirm the version exists on the public
registry the stack uses, under the expected name, with the checksum the
lockfile will record when the stack keeps a lockfile, or the registry's
published hash otherwise:

| Stack | Check |
| --- | --- |
| Go | `GOPROXY=https://proxy.golang.org go list -m -json <module>@<version>` |
| npm | `npm view <package>@<version> dist.integrity` |
| Rust | `cargo info <crate>@<version>` or the crates.io API |
| Python | `pip index versions <package>` or the PyPI JSON API |
| Ruby | `gem info <gem> --remote --version <version>` |
| JVM | the artifact directory exists on Maven Central, `https://repo1.maven.org/maven2/<group path>/<artifact>/<version>/`, or the Central search API |
| Actions | the tag exists on the action's repository, `gh api repos/<owner>/<action>/git/ref/tags/<tag>` |
| Any other stack | the registry's own lookup for the name and version |

A version the registry does not know, a package that resolves only from a
git or path source, a renamed path, a name one character away from a known
one, or a new install-time hook stops the batch and goes to `pr-audit`.

## Step 3: consolidate

```sh
git switch -c <bump branch in the project's naming, e.g. build/bump-deps> <default>
```

Update every qualifying dependency together with the package manager
(`go get ... && go mod tidy`, `npm update <pkg> ...`, `cargo update -p
<crate> ...`, `bundle update <gem> ...`, `pip-compile --upgrade-package
...`, or the version catalog or build file for Gradle and Maven). When
the stack keeps no lockfile, the bot's manifest edit is the update: apply
it and reinstall. The target is the newest version the existing
constraints allow, which may be newer than the bot proposed; note that in
the report. Do not widen constraints, jump a major, or add an override to
chase a version.

For a workflow action bump, edit the pin to the version the bot proposed
and nothing else.

## Step 4: gate once

Run the project's gate on the consolidated tree. If it fails, find whether
the cause is the bump, the environment or a pre-existing fragility, make
the smallest fix as its own commit on the same branch, and rerun. Never
un-bundle the batch back into per-PR merges to bisect; bisect in a scratch
worktree and express the result as a pin.

## Step 5: land

```sh
git add <manifest>              # and the lockfile when the stack keeps one, or the workflow file
git commit -m "<subject in the project's convention: bump a to x, b to y>"
git push -u origin <bump branch>
gh pr create --base <default> --title "<subject>" --body "Closes #A
Closes #B"
gh pr checks --watch   # when the project has hosted checks
gh pr merge --<merge|rebase|squash> [--delete-branch]
```

A merge the branch protection refuses for lack of a review the runner
cannot supply is reported as ready and awaiting review, not retried. Every
bot PR the merge did not close gets a comment with the reason and is
closed by hand. A deferred bump is never left silently open with a red
build: comment, then close it or open a tracking issue.

## Output

```markdown
## Dependency bump

- Closed: #A, #B
- Versions: <package> a -> b (newer than the bot's c), ...
- Gate: <result>; hosted checks: <conclusion> on <SHA>
- Handed to pr-audit: #C (<reason>)
- Deferred and closed with a comment: #D (<reason>)
```
