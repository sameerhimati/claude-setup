---
name: oss
description: >-
  Prepares a repository to be made public: scans git history and the working tree for secrets,
  audits what actually ships, reads the docs for internal-only or false claims, checks license
  and attribution, then clones clean and follows the README as a stranger. Use when
  open-sourcing a repo, making something public, or asking if a repo is safe to publish.
---

# OSS: prepare $ARGUMENTS to be public

Run from inside the project repo. If `$ARGUMENTS` names a different path, `cd` there first and say so.

## Iron Laws

1. **Secrets are rotated, not deleted.** A key that was ever committed is burned the moment
   the repo goes public, whether or not the current tree still has it. Deleting the file does
   not unpublish the history. Rotate first, then clean.
2. **The stranger test is the only proof.** A clean clone, an empty environment, and the
   README followed literally. Nothing on the author's machine counts. Every dead-end is a bug,
   not a documentation preference.
3. **Public is one-way.** Anything named in this report as a hard gate blocks the flip. Soft
   findings can ship and get fixed after.

## Step 0 — Ground

```bash
git remote -v && git status -sb && git log --oneline -5
gh repo view --json name,description,isPrivate,visibility,licenseInfo,repositoryTopics,homepageUrl,stargazerCount 2>/dev/null
```

Detect the stack (package.json / pyproject.toml / go.mod / Cargo.toml), whether this is a
**library/CLI** (ships to a registry) or an **app** (ships as a clone), and whether it was
forked or started from a template.

If the repo has uncommitted work or a session is active elsewhere, say so and ask before
editing. Concurrent sessions on the same repo are common here.

Ask up front, in one pass, only what you cannot infer:
- License, if there isn't one (default recommendation: **MIT**).
- Is it also publishing to a registry (npm / PyPI), or GitHub-only?
- Anything deliberately staying private (a client name, a dataset, an internal doc).

## Step 1 — Secrets and history (HARD GATE)

This is first because it is the only step that cannot be undone after the flip.

**Working tree:**
```bash
git ls-files | grep -iE '(^|/)\.env($|\.)|\.pem$|\.key$|credential|secret|token|\.pfx$|id_rsa|serviceaccount|\.p12$'
grep -rInE '(sk-[A-Za-z0-9_-]{16,}|ghp_[A-Za-z0-9]{20,}|xox[baprs]-|AKIA[0-9A-Z]{16}|npm_[A-Za-z0-9]{30,}|-----BEGIN [A-Z ]*PRIVATE KEY-----|Bearer [A-Za-z0-9._-]{20,})' \
  $(git ls-files) 2>/dev/null | head -40
```

**Full history** — the part people skip:
```bash
git log --all --name-only --format='%H' | grep -iE '(^|/)\.env($|\.)|\.pem$|\.key$|credential|secret' | sort -u
git log --all -p -S'sk-' --oneline | head
git rev-list --objects --all | sort -k2 | uniq -f1 -d | head    # same path, many blobs
```

Also check for things that are not credentials but are still not yours to publish:
customer data, scraped datasets, resumes, exported DB dumps, screenshots with real accounts,
`.sourcery`/`.claude`/`data/` directories holding real runs.

**If anything real is found in history:**
1. Rotate the credential *now*, before touching git. Name the exact console URL.
2. Then choose, and make Sameer choose — do not pick silently:
   - `git filter-repo` / BFG to excise, force-push, everyone re-clones. Correct for a repo
     with collaborators or a history worth keeping.
   - Squash to a single initial commit and push fresh. Correct for a solo hackathon repo
     where the history is 40 commits of one weekend and nobody has cloned it.
3. Re-run the scan on the rewritten history before continuing.

**Report clean explicitly.** "No secrets in history" is a finding worth stating.

## Step 2 — What actually ships

```bash
git ls-files | wc -l
git ls-files | awk -F/ '{print $1}' | sort | uniq -c | sort -rn | head -20
git ls-files -z | xargs -0 du -h 2>/dev/null | sort -rh | head -15    # biggest tracked files
```

Look for tracked build artifacts and machine state: `dist/`, `.next/`, `build/`,
`*.tsbuildinfo`, `node_modules/`, `__pycache__/`, `.venv/`, `.DS_Store`, lockfiles that
should ship (keep) vs caches that shouldn't (drop), and media over ~10MB.

Fix `.gitignore` to cover what you found, then `git rm --cached` anything already tracked
that shouldn't be. Note that `.gitignore` does not untrack — say so when you do it.

**If it publishes to a registry**, the tarball is a second, different question:
```bash
npm pack --dry-run 2>&1 | tail -30        # or: python -m build && tar tzf dist/*.tar.gz
```
Two failure modes, both common: shipping too much (source, tests, docs, secrets), and
shipping too little — README or error messages that reference a file `files:` excludes.
That second one is invisible from a clone and only shows up in Step 4.

## Step 3 — Read every doc (HARD GATE for the false ones)

Enumerate and actually read them: `README`, `docs/**`, `CONTRIBUTING`, `HOWTO`, `ROADMAP`,
`CLAUDE.md`, `AGENTS.md`, and every stray `*.md` at root.

Flag, per file:

- **Internal-only content.** Session handoffs, sprint plans, `session-handoff.md`,
  `HANDOFF-*.md`, TODO dumps, personal notes, anything addressed to a future Claude session.
  These are not shameful, they are just not the artifact. Move to a `.gitignore`d directory
  or delete. Keep `CLAUDE.md`/`AGENTS.md` only if they are genuinely useful to a contributor
  using an agent; strip anything about the author's own workflow.
- **Private references.** Client names under NDA, unlaunched company details, internal URLs,
  personal absolute paths (`/Users/<name>/...`), unredacted account ids, pricing from a
  private contract.
- **Claims that are not true any more.** Every number, benchmark, and "it does X" in the
  README gets checked against the code or against the run that produced it. A stale
  performance claim in a public README is the one that costs credibility. If a claim can't
  be verified, cut it or mark it as measured-once-on-this-date.
- **Instructions that only work here.** "Defaults to the author's vault", hardcoded ports
  already in use, a `make` target that assumes a local dataset. Each of these is a Step 4
  failure waiting to happen.
- **Broken links.** Check every internal path exists and every external link resolves.

The README's job, in order: what it is in one line, why it exists / what it found, how to
get to a first result, what it costs, and what it can't do. **An honest limitations section
is an asset** — it is the strongest signal of someone who actually ran the thing.

## Step 4 — The stranger test (HARD GATE)

The centerpiece. Do not skip it because the code obviously works.

```bash
TMP=$(mktemp -d) && git clone --depth 1 "file://$PWD" "$TMP/probe" && cd "$TMP/probe"
env -i PATH="$PATH" HOME="$TMP/home" bash -l    # no keys, no author state
```

For a registry package, do the harder version: pack the tarball, install it into an empty
directory, and run it from there — that is the only way to catch a `files:` exclusion.

Then follow the README **literally**, top to bottom, typing exactly what it says. Record
every one of:
- A command that doesn't exist, or a step that assumes a prior step the README never lists.
- An error message that names a file the user doesn't have, or that is a stack trace where
  a sentence belongs.
- A required key with no link to where you get it, and no note on whether it's free.
- A first run that costs money, or silently spends, with no dry-run and no ceiling.
- Silence for more than ~10 seconds with no progress output.
- Any point where the honest next action is "read the source."

**Time to first success is the metric.** Under five minutes, with at most one free key, is
the target for anything you want people to actually try. If the real answer is 40 minutes and
three paid APIs, that is allowed — but then the README must offer a **fixture, sample, or
shipped-reference path** that shows the output without the full setup. A stranger who cannot
see the result will not build the setup to find out if it was worth it.

## Step 5 — License and attribution (HARD GATE)

- `LICENSE` file exists at root, real year and name, and **matches** what `package.json` /
  `pyproject.toml` claims. GitHub must detect it — check `gh repo view --json licenseInfo`.
- If this started from a fork, template, or starter: is the upstream license compatible, is
  it credited, and does the README say plainly **which parts are yours**? If the upstream has
  no license at all, that is a real problem — flag it, and say so in the attribution rather
  than papering over it.
- Vendored assets (video, images, data, fonts) each need a source and a license line.
- Dependency licenses: scan for GPL/AGPL under a permissive claim.

## Step 6 — Repo surface

The first fifteen seconds. Cheap, and usually the last thing done.

- **Description** set, and it says what it does, not what it is built with.
- **Topics** — 5-10, this is the only discovery surface GitHub gives you.
- **Homepage** pointed at docs or a demo, not a generic personal site.
- Issues enabled. Stale branches deleted. CI badge only if CI is green.
- **A visual in the first screen.** A terminal GIF (`vhs`/`asciinema`) for a CLI, a screenshot
  or 20-second clip for an app. This is the highest-leverage remaining item on almost every
  repo that reaches this step — the README argument is already good, and nobody reads it
  before they see something.
- `CONTRIBUTING.md` only if contributions are genuinely wanted; a stub is worse than nothing.
- A tagged release matching whatever is published.

## Step 7 — Report, then fix

Report before editing anything beyond trivial fixes. Format:

```
REPO: <name>  ·  <public|private>  ·  <n> tracked files

HARD GATES (block the flip)
  1. <finding> — <file:line> — <the fix>
SOFT (ship and fix after)
  1. ...
ALREADY GOOD (don't touch)
  - ...

TIME TO FIRST SUCCESS: <n> min, <n> keys required, <free|paid>
RECOMMENDATION: <flip it | fix N first | not close, here's the gap>
```

Then fix in gate order, one logical change per commit, re-running the stranger test after
anything that touches setup or docs. Do not flip visibility yourself — that is Sameer's
call, and it is one-way.

End with **DONE** / **DONE_WITH_CONCERNS** / **BLOCKED** per `_conventions.md`.

## Notes

- Repos that were hackathon projects need Step 3 hardest: they accumulate demo scripts,
  judge-facing docs, and handoff notes that read as clutter to anyone who wasn't there.
- Repos that were AI-built need Step 4 hardest: the code works on the machine it was built
  on, and every assumption that machine satisfied is invisible until a clean clone.
- When a finding is genuinely a judgement call — squash vs excise, keep vs cut a doc — use
  `AskUserQuestion` with a recommendation, per `_conventions.md`.
