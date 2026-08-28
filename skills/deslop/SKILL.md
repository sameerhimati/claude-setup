---
name: deslop
description: >-
  Rewrites machine-sounding prose into the author's own voice, and strips LLM tells from drafts they
  wrote themselves. Use when text reads as AI-written or generic, when asked to make writing "sound
  more like me", "less like ChatGPT", or "less AI", or when de-slopping a README, blog post, doc,
  email, PR description, or landing copy.
---

# Deslop: $ARGUMENTS

Strip the tells that mark prose as machine-written. Keep the author's voice.

## The voice file

Voice work needs samples. `voice.local.md`, next to this file, holds the author's own — real
writing of theirs, plus the specific tells to watch for. It is deliberately not committed: a voice
guide built from one person's essays is useless for anyone else, and worse than useless if applied
to them.

If `voice.local.md` is missing, do not guess at a voice. Say so, and offer to build one: ask for
three or four pieces the author actually wrote, read for what recurs, and write the file. Until it
exists, run in audit mode only — name the tells, don't rewrite.

## Iron Law

**Delete the tell, keep the sentence.** This is an edit, not a rewrite.

The failure mode is not missing a tell — it is "fixing" the piece into your own
voice, which is the same slop wearing a different coat. If a sentence has no tell
in it, it does not get touched, however you would have written it. Sameer's
argument, structure, jokes, and rhythm survive intact.

If more than about a third of the text needs changing, stop and say so. That is
not a de-slop job; the piece needs rewriting by its author, and doing it for them
loses the thing worth keeping.

**But subtraction alone does not finish the job** (established 2026-08-17, after
Sameer reported prose still reading as machine-written *after* a clean pass).
Removing every tell leaves neutral, competent prose — and neutral competent prose
*is* the LLM baseline. What you get is slop minus the obvious markers: harder to
name, still not his. Step 4.5 exists for that half.


## Step 0: The cut pass — should this text exist at all?

**Runs first, before every other step** (added 2026-08-17, after Sameer read a
README that had been de-slopped and asked why the story was in there at all).
Editing prose that shouldn't be on the page is wasted work, and it is the most
common thing wrong with anything Claude wrote.

**The root cause: I have no cost function for length.** I know how to write more,
never what to leave out, so every section I can justify appears. He writes the
minimum because writing is work. I don't pay that cost, so nothing gets cut unless
this step cuts it.

Go section by section and ask **"what is this page for, and does this earn its
place on it?"** — not "is this good." Most of what gets cut is good. It is just in
the wrong file.

**Cut on sight:**

- **Anything that already lives elsewhere in the repo and is linked.** A README
  carrying the findings narrative *and* a link to `docs/findings.md` is the
  canonical case. Link it, cut it.
- **The story of building it.** Narrative belongs in a post or a findings doc.
- **Justification prose** — paragraphs explaining why a design choice is right.
  One line, or a link, or nothing.
- **Any section whose real job is to prove the author thought hard.**

**What a README is actually for:** what it is (one to three sentences) · quickstart
· what you need to configure · the command or API surface · links to everything
else. That is close to the whole list.

⚠️ **This does not contradict "provenance and opinion."** Those belong as **lines,
not sections.** "Built in 6 hours at a hackathon; PageRank ranked Shapley Value
above Game Theory so I threw it out" is one sentence and it earns its place. Eight
paragraphs of the same material is an essay wearing a README's filename.
`delta-learning/README.md` gets this right: a short status block, then it points at
the findings.

**Report the cut as a list of sections with a destination for each** — moved to
`docs/x.md`, folded to one line, or deleted. Never silently drop content that has
nowhere to go, and never delete the only copy of something. If a cut section has no
home, say so and let him decide.

**Then** run the voice work below on what survived.

## Two axes: authorship picks the mode, surface picks the register

Keep them separate. Conflating them is how a doc gets his blog voice, or a blog
post gets Google's.

| | Question | Answers |
|---|---|---|
| **Mode** | Whose sentences are these? | edit (his) · voice (Claude's) |
| **Register** | What surface is this? | reflective · technical · docs |

**Mode** decides whether you may rewrite a sentence at all. **Register** decides
what good looks like once you may.

### The three registers

- **Reflective** — posts, DMs, essays. Loose, unproofed, funny. Authority is
  `voice.local.md`. Typos stay.
- **Technical** — READMEs, PR bodies, commit messages, findings docs. Clean,
  declarative, first-person, still opinionated. Authority is `voice.local.md`'s
  technical register.
- **Docs** — API reference, CLI help, error text, config reference, the command
  and quickstart sections of a README. **Authority is
  `references/google-style.md`.** There is no personal voice here and there
  should not be one; the reader wants the fact.

A single README usually contains two registers: the opening and the provenance
lines are technical, the command surface is docs. Edit each as itself.

⚠️ **The docs register never touches personal prose.** `google-style.md` opens
with a guard listing the rules that would damage it — front-loading the
paragraph, banning metaphor, second person, present tense, correcting spelling.
Every one reads as a legitimate correction, which is why the guard exists. Read
it before applying a single rule from that file.

## Two modes, and the trigger is authorship

**Ask one question first: whose sentences are these?**

### Edit mode (default) — Sameer wrote it

The Iron Law above holds completely. His drafts, his posts, his DMs, his
application essays. Delete the tell, keep the sentence. Rewriting his prose
destroys the exact thing worth keeping, and `feedback_writing_voice` — *assist,
don't ghostwrite* — governs here without exception.

### Voice mode — Claude wrote it

**READMEs, docs, PR bodies, landing copy, commit messages, changelogs.** Here the
Iron Law inverts: the sentences were never his, so there is nothing to preserve
by keeping them. Preserving them is the bug. **Rewrite into his voice.**

Trigger it by authorship, by `--voice`, or by him saying rewrite. When it's
genuinely unclear who wrote something, ask — do not guess and rewrite his prose.

**The preservation contract, absolute in both modes:** every fact, number, name,
link, file path, code block, table, YAML block and claim survives exactly.
Rewrite mode may change any sentence. It may never change, soften, strengthen or
invent a single piece of content. If the rewrite wants a fact it doesn't have —
where this came from, what broke, what he'd redo — **it asks him. It does not
supply one.**

### The rewrite operations

Work from `voice.local.md`, and pick the register first:
**reflective** (loose, unproofed, swears) or **technical** (clean, declarative,
teaching). A README is technical. A post about a month off code is reflective.

Then, concretely:

- **Delete the setup sentence.** Start on what was the second sentence. He opens
  flat — *"It's been a while since I've written."* No hook, no thesis paragraph.
- **Cut the closer whole.** The final paragraph that restates the piece almost
  always deletes with nothing lost. End on the last real point, or two words.
- **Break the rhythm.** LLM prose is all medium sentences. Give it one fragment,
  or one long comma-spliced one. *"Great place to be, lovely weather and an active
  buzz of keyboards clacking reverberates across all the cafés I've visited."*
- **Demote the best line.** If the strongest sentence sits in a header or stands
  alone for effect, move it mid-paragraph and strip the emphasis. Undecorated.
- **Hedge → position.** "can be considered" → "is". "may help" → "does".
  "it's worth noting that X" → "X".
- **Abstraction → the instance he actually used.** Not "several providers" but
  "Firecrawl, Tavily, Exa and Bright Data". Not "significant improvement" but the
  number.
- **Register the contractions.** Technical writes out *it is / that is*.
  Reflective contracts, and leaves "Its" and "doesnt" alone.
- **At most one self-deprecating aside**, in parens, per piece.
- **Kill the em-dash tic.** He uses commas and run-ons.
- **Second person to teach, first person to claim.** *"You ask, it answers."* /
  *"Here is how I have come to hold it."*

**Check your own replacements — this is where the slop actually comes from.** (Added
2026-08-19, after a résumé pass where every phrase Sameer flagged was one *I* had just
written, not one I'd failed to remove.) Every sentence you write to replace one of his is
fresh text from the same model that produces the tells. Before shipping any replacement, run
it against the "Claude's tells" section of `voice.local.md`: is it alliterative, balanced,
quotable, or elegantly subordinate? If yes, it is worse than what it replaced, however much
cleaner it reads. Rewrite it flatter and plainer, and prefer the dull true phrasing over the
well-made one.

**Stop condition for voice mode:** if the rewrite is drifting into a *better*
piece rather than *his* piece, you are writing as yourself again. Ship the plainer
version.

## Audit mode — `--audit`

**Report and do not edit.** Borrowed from `hallmark audit`, after that verb found
three real errors in a page its own author had defended as fine. The value is
that a punch list is arguable and a diff is not: he can reject item 4 in one line
without unpicking a commit.

Run Steps 0–4.5 as normal, then stop before applying anything. Return:

1. **A score out of the checks you ran**, e.g. `41 / 48 patterns clean`.
2. **A ranked punch list, worst first.** Each item: `file:line` · what it is ·
   the concrete fix · which rule or category it comes from.
3. **The self-critique below**, scored honestly.
4. **What you would have left alone and why.**

Do not use Edit or Write in this mode. If the text is a file he can open, quoting
the line is enough.

`--audit` composes with the registers: an audit of a docs surface scores against
`google-style.md`, an audit of a post scores against `patterns.md` and
`voice.local.md`.

## Step 1: Read the source

`$ARGUMENTS` is a file path, a glob, or pasted text. For a path or glob, Read
every match in full before editing anything — a tell is often only visible
against the paragraphs around it (three sections that each open the same way is
a tell; one section opening that way is a sentence).

If `$ARGUMENTS` is empty, ask what to de-slop. Do not guess at recently edited
files.

**Also read `voice.local.md` before editing.** It carries the
two registers (reflective vs technical) and the specific habits that must survive
the pass — the unproofed typos, the buried best line, the abrupt ending. Editing
without it, you will "fix" the exact things that make the prose his.

## Step 2: Scan against the pattern list

Read `references/patterns.md` and scan for each category. Do not work from
memory — the list exists because the tells drift and recall of them is exactly
what a model is worst at.

**In the docs register, also read `references/google-style.md`.** In the other
two, don't — it costs context and its rules do not apply. Where the two files
agree (`in order to` → `to`, the throat-clear, keeping the Oxford comma), cite
google-style: a rule is a better answer to "why did you change that" than a
hunch.

`google-style.md` catches nine things `patterns.md` has no entry for at all:
anthropomorphism, floating "this", *i.e.*/*e.g.*, passive voice with its three
legitimate exceptions, dropped articles, curly quotes, possessives on code
identifiers, abbreviations used as verbs, and sentence-case headings.

Record every hit as `file:line — "phrase" → replacement`. Build the whole list
before making a single edit, so you can apply Step 3's judgment across the piece
rather than one line at a time.

**Completion criterion:** you have scanned for every category in
`patterns.md`, not just the vocabulary one. Structural and rhythm tells are the
higher-signal half and the easier half to skip.

## Step 3: Judge each hit before applying it

A pattern match is a candidate, not a verdict. Drop the hit when:

- **The word is load-bearing.** "Delve" in a piece about mining. "Robust" as a
  term of art in statistics. The list flags phrasing that carries no information;
  where it carries information it stays.
- **It is a quotation.** Never edit inside quoted text, a transcript, a citation,
  or a code block. Quoting someone who wrote "leverage" is reporting, not sloppy.
- **It is the author's actual habit.** If the same construction appears in older
  writing that predates the piece, it is a voice, not a tell. Check with
  `git log -p` on the file, or another file in the same directory, when unsure.

Whatever survives this step gets applied with Edit, one phrase at a time.

## Step 4: Read it aloud, then check the rhythm

Vocabulary edits are the easy half; the giveaway that survives them is cadence.
After applying the edits, reread the piece for:

- Paragraphs that are all the same length.
- Sentences that are all medium-length, with no fragment and no long one.
- Every section opening with the same move (a question, a definition, a "when it
  comes to X").
- A summary paragraph that restates what the reader just read.

Fix these by cutting, not by adding. The last one is almost always deletable
whole.

## Step 4.5: The presence pass — does it sound like *him*?

Steps 2–4 ask "does this read as a machine." This step asks the harder question:
**does anything here read as Sameer.** Absence of tells is not presence of voice.

Check against `voice.local.md` for what should be *there*:

- **Is there a lived specific?** A number, a place, a time, a thing that went
  wrong. "the occasional whiff of piss around certain corners" · "a foggy Tuesday
  evening in June" · "PageRank ranked Shapley Value above Game Theory". These are
  the fastest tell of a real author and the one thing no model can fabricate.
- **Is there an opinion he'd defend?** Not a balanced assessment — a position.
- **Did the piece admit something?** A mistake, a limit, a thing he'd redo.
- **Does it start flat and end abruptly**, or has it grown a hook and a summary?
- **Are the good lines still buried?** If the edit promoted his best sentence to a
  header, put it back mid-paragraph. Undecorated is the point.

**The diagnosis when a piece survives Steps 2–4 and still reads as AI:** it is
almost never word choice. It is **not enough specific true content.** Do not
reach for more edits — that makes it blander. Say so plainly and ask him for the
fact, the number, the thing that broke. Voice mostly takes care of itself once
real content is in.

This step may **not** invent the specifics. Asking is the deliverable.

### Score it before you ship it

(Added 2026-08-19, from Hallmark's pre-emit critique. Step 4.5 asked the right
question and nothing forced a second pass, so the answer was always "yes, fine".
Scoring it forces the pass — and when the scores were done honestly on a page
this session, a claimed 4 was really a 3, and the gap was where all the work
turned out to be.)

Score the result 1–5 on each. **Anything below 3 triggers another pass before you
ship**, and you say what you changed.

| Axis | 5 looks like |
|---|---|
| **Voice** | Reads as him, or as the register. Not as competent neutral prose |
| **Specificity** | Carries a number, a name, a place, a thing that went wrong |
| **Position** | Takes one. Not a balanced survey |
| **Restraint** | Nothing added that was not there. No new flourish of yours |
| **Shape** | Starts flat, ends abruptly, best line still buried |

Report the five scores with the result. A generous score is worse than a low one,
because it is the thing that stops the second pass from happening.

**Restraint is the one to be hardest on**, because it scores *your* additions
rather than his prose, and every replacement sentence is fresh output from the
model that produces the tells.

## Special case: READMEs, docs, and other factual surfaces

These read as slop for a different reason — Claude authored them, and they are
mostly factual, so there is little style to correct. **The fix is provenance and
opinion, not prose.**

Audit for, and ask him to supply, the five things a machine cannot know:

1. **What it is** — one sentence, no adjectives.
2. **Where it came from** — a hackathon, a client, an itch, a bet.
3. **What surprised him** while building it.
4. **What he'd do differently.**
5. **What it deliberately does not do.**

> "Built in 6 hours at a hackathon. PageRank ranked Shapley Value above Game
> Theory, so I threw it out — first-teaching-time won 10/10 vs 7/11."

No model writes that sentence, because no model knows it. One line like it
outperforms a full de-slop pass on the surrounding page.

## Optional: plain-English mode

Off by default. Runs only when Sameer asks for it — "plain English", "simpler",
"--plain" — because it relaxes the Iron Law for *register* while keeping it for
content. Borrowed from [claudish-to-english](https://github.com/gvzdv/claudish-to-english),
whose entire method is the two rules below.

After Steps 2–4, make one more pass that rewrites for a reader in a hurry:

- Short sentences. Everyday words. If a simpler word says the same thing, use it.
- **The preservation contract:** keep every fact, name, number, link, and file
  path exactly. Fenced code blocks, YAML frontmatter, and quotations are
  reproduced untouched. Markdown structure (headings, lists, tables) stays.

This mode may reword sentences that have no tell in them — that is the point of
opting in. It still may not cut claims, reorder the argument, or add anything.
Report it as its own row group in Step 5 so the two kinds of change stay
distinguishable.

## Step 5: Report

State which mode you ran, and why you judged the authorship that way.

In edit mode, show a table of what changed and why:

| Location | Was | Now | Tell |
|---|---|---|---|

Then state, explicitly:

- **What you left alone and why** — every hit dropped in Step 3. This is the
  most useful part of the report, because it is where you might have been wrong,
  and Sameer can overrule you in one line.
In **voice mode** a line-by-line table is noise, since most lines changed. Report
instead: the register you picked and why · what structurally went (the setup
sentence, the closer, any promoted line put back) · **and the facts you wanted and
didn't have.** That last list is the deliverable — it is what he alone can fill,
and it is what makes the page his rather than merely readable.

- **Whether the rhythm pass changed anything structural** (a cut paragraph, a
  merged section), since that is a bigger intervention than a word swap.

End with `DONE` or `DONE_WITH_CONCERNS` per `_conventions.md`. Use
`DONE_WITH_CONCERNS` when you hit the one-third rule in the Iron Law, or when a
tell is load-bearing enough that removing it would change the meaning and you
left it in.

## Notes

- The related instrument inside **hunt** (`src/lib/checks/ai-tell.ts`) is a
  deterministic regex audit over résumés and cover letters, with a narrower,
  résumé-tuned list. Deliberately separate: it runs in a product UI on every
  keystroke and cannot exercise Step 3's judgment. If a pattern proves itself
  here and is objective enough to regex, it is worth porting there by hand.
- Report the reading as "this pattern-matches LLM boilerplate", never "this is
  AI-generated". The first is checkable; the second is a claim about the writer
  that no one can verify.
