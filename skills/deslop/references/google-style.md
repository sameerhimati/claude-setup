# Google developer documentation style, as rules

Extracted 2026-08-19 from <https://developers.google.com/style>, page by page.
Cited so a disagreement is an argument about a rule rather than about taste.

**This file governs one register only: documentation.** Read
`SKILL.md` § "Docs register" for the scope. It is authority for API docs, CLI
help, config reference, and the command sections of a README. It
has **no authority over Sameer's personal writing**, and the § "Never apply these
to personal prose" list below exists because several rules here would actively
damage it.

Google's own position on its rules, quoted from the guide's front page:

> This guide contains guidelines, not rules. Depart from it when doing so
> improves your content.

So does this file. A rule below that makes a sentence worse loses.

---

## Never apply these to personal prose

Hard guard. In a blog post, a DM, a reflective essay, or any first-person piece
of his, these rules are **off**. Applying them is the failure mode this file is
most likely to cause, because each one reads as a legitimate correction.

| Rule | Why it is wrong here |
|---|---|
| Avoid first person, prefer second person (`/pronouns`) | His personal register is first-person throughout |
| Circumstance before instruction (`/sentence-structure`) | Forces every sentence conditional-first. Kills the sustained metaphor, the buried line, the trailing-off ending |
| Third-person verbs in reference docs (`/reference-verbs`) | Scoped to API method descriptions. Nothing else |
| No ellipses, no exclamation points (`/ellipses`, `/periods`) | The guide itself exempts blog posts and tutorials |
| Anthropomorphism ban (`/anthropomorphism`) | Applies to *software as subject* only. Personification as a rhetorical device stays |
| Correct the spelling | Not a Google rule at all, and directly against `writing-voice.md`: leave "Its been" and "doesnt" alone |
| **Front-load the paragraph. "Don't hide the key point of a paragraph at the end" (`/paragraph-structure`)** | **The sharpest conflict in the guide.** `writing-voice.md` says he *buries the best line* and *sustains a metaphor before revealing it*. This rule would invert both. Never apply it to his prose |
| Sentence-case headings, no -ing openers, unique h1 (`/headings`) | A post titled as a question or a fragment is normal. Docs taxonomy is for navigating a doc set |
| The four-type notice system (`/notices`) | An aside in an essay is prose or a parenthetical, not a boxed callout |
| Avoid footnotes (`/footnotes`) | Their reasoning is localisation and accessibility at scale. Essays use asides for voice |
| Link text rules — never "click here" (`/cross-references`) | Right for docs. In a post a casual "here" often reads more human |
| **"Don't use metaphors, and don't use a term in a metaphorical sense" (`/inclusive-documentation`)** | **Tied for the sharpest conflict.** *A Month Off Code* runs three paragraphs of addiction language before revealing it is about coding agents. Google's rule bans exactly that move. It is right for docs, translated into forty languages, and it would gut his best technique |
| Ban on *now*, *currently*, *new*, *latest* (`/timeless-documentation`) | A docs virtue and a memoir defect. "Its been exactly a month since I landed" is anchored on purpose |
| Delete *just*, *easy*, *simply* as filler | Often right for him too, but not categorically — his register carries *kinda*, *idk*, *prolly*, and a strict precision scrub takes those as well |

**Two things the guide does not say, and that this file must not be read as
saying.** There is no sentence-length rule and no one-idea-per-sentence rule
anywhere in it. And its contraction guidance is *permissive* — it recommends
"you're", "don't", "isn't" for readability, and bans only nonstandard
three-word forms like "mightn't've". Do not turn either into a restriction.

---

## The high-value rules

The ones worth reaching for first, because they catch machine-written prose that
`patterns.md` does not.

### Anthropomorphism — `/anthropomorphism`

> Don't attribute human qualities to software or hardware.

The single best mechanical check in the guide for prose about software. Flag any
verb of cognition, perception, desire, or communication with a non-human subject:
*thinks, wants, knows, sees, understands, decides, tells, believes, remembers,
tries, expects, learns, realises, feels*.

- not this → "A Delimiter object **tells** the splitter where a string should be broken."
- this → "A Delimiter object **specifies** where to split a string."
- not this → "The PC **sees** a new device."
- this → "The PC **detects** a new device."

The distinction: *tells* and *sees* imply intent and awareness; *specifies* and
*detects* describe function. Reach for: specifies, detects, returns, requires,
reports, stores, matches, rejects.

**Scope it before you fire it — the check over-fires.** Tested against real prose
2026-08-19; both hits were drops:

- *"The judge never answers the question. It **sees** one question and one page
  and **says** whether that page helps."* — the judge is a language model, and
  "sees" and "says" are the plainest words available. "Receives" and "outputs"
  are worse writing and no clearer. **Keep.**
- *"None of this appears in a relevance score, and it **decides** what you can
  build."* — the subject is an abstraction, not software. Google's rule is scoped
  to software and hardware. **Keep.**

The rule fires only when **a named piece of software or hardware is the subject**
of a cognition, perception, desire, or communication verb. An abstraction that
"decides", or a document that "says", is ordinary English. And a language model
is the one piece of software where a cognition verb is least misleading — weigh
that before rewriting it into something stiffer.

### Floating demonstratives — `/pronouns`

Every pronoun needs an unambiguous antecedent, and a demonstrative needs its
noun. A bare "this" opening a sentence is the most common version in generated
prose.

- not this → "Set this to true."  this → "Set this **value** to true."
- not this → "If you type text in the field, **it** doesn't change."  this → "…the **text** doesn't change."

### Latin abbreviations — `/abbreviations`

Never *i.e.* or *e.g.* Write "that is" and "for example". `etc.` sparingly.
Never *tl;dr*, *ymmv*, *RTFM*.

### Active voice — `/voice`

Say who does the thing.

- not this → "The service is queried, and an acknowledgment is sent."
- this → "Send a query to the service. The server sends an acknowledgment."

**Passive is correct** in three cases, and stripping it there is its own error:
to emphasise the object ("The file is saved"); to de-emphasise the actor ("Over
50 conflicts were found in the file" beats "You created over 50 conflicts"); and
when the actor is irrelevant ("The database was purged in January").

### Clause order — `/sentence-structure`

Circumstance, condition, or goal **before** the instruction, so a reader can skip
an instruction that does not apply to them. **Docs only** — see the guard above.

- not this → "See [link] for more information."  this → "For more information, see [link]."
- not this → "Click **Delete** if you want to delete the entire document."  this → "To delete the entire document, click **Delete**."

### Parentheses — `/parentheses`

Prefer a comma, a dash, a semicolon, or a second sentence. Never bury important
information in parentheses — readers skip them. If a parenthetical runs long,
split the sentence.

### Articles — `/articles`

Never drop *a*, *an*, or *the* for brevity, including in headings.

- not this → "Create VM instance"  this → "Create a VM instance"

### Abbreviations as verbs — `/abbreviations`

- not this → "ssh into your remote shell"  this → "Use SSH to log in"

---

## Mechanical rules

Checkable without judgment. Grouped by what they touch.

### Punctuation

| Rule | Page |
|---|---|
| Serial comma, always: "zones, regions, **and** multi-regions" | `/commas` |
| Em dash takes **no spaces** on either side | `/dashes` |
| En dash: **never use one.** A hyphen, or the word "to" | `/dashes` |
| Number ranges take a hyphen: "8-20 files", or "from 8 to 20 files" — never mix "from" with a hyphen | `/hyphens` |
| Straight quotes only. Never curly | `/quotation-marks` |
| Commas and periods inside quotes — **except** around a literal or keyword, where they go outside | `/quotation-marks` |
| Ellipsis is three literal periods, never the `…` character. Never for hesitation in prose | `/ellipses` |
| Comma before *and*/*but* joining two independent clauses, unless both are very short | `/commas` |
| Semicolons: avoid. Three sanctioned uses — joining related independent clauses, before a conjunctive adverb, and separating list items that contain commas | `/semicolons` |
| A colon's lead-in must be a complete sentence: not "The fields are:" but "The fields are defined as follows:" | `/colons` |
| Lowercase after a colon, unless a proper noun, heading, quotation, or a label like "Caution" | `/colons` |
| Slashes only in code, paths, and URLs. Never "and/or", never for alternatives, never "w/" | `/slashes` |
| Period inside the parentheses when the whole sentence is parenthetical; outside when only part is | `/parentheses`, `/periods` |
| One space between sentences | `/periods` |
| Never end a sentence on a URL — rewrite, or put it on its own line with no trailing period | `/periods` |
| Exclamation points: never in concept, reference, or procedural docs | `/periods` |
| A hyphen or spaced dash is not a colon: not "Example - This is one" but "Example: this is one" | `/dashes` |

### Hyphenation — `/hyphens`

- Hyphenate a compound modifier before a noun only when clarity needs it:
  "well-designed app", "Android-specific techniques". No hyphen after a verb:
  "well designed".
- Number plus a spelled-out unit modifying a noun: hyphenate. "64-bit system",
  "five-minute wait". Abbreviated units: don't. "200 GB disk".
- **Never hyphenate an `-ly` adverb.** "publicly available".
- No hyphen between a prefix and its noun by default: "infrastructure",
  "preprocessing". Exceptions for *self-* and *cross-*, a capitalised or numeric
  root ("non-Google", "post-2000"), and clarity ("re-sign" vs "resign").
- Compound nouns close up by default: "webpage", "workaround".
- No space around a hyphen, except a suspended one: "one-, two-, or three-hour".

### Words and grammar

| Rule | Page |
|---|---|
| *that* for restrictive clauses, no comma. *which* for nonrestrictive, comma required | `/pronouns`, `/commas` |
| Singular **they**. Never *he/she* or *(s)he* | `/pronouns` |
| Prepositions may end a sentence — don't contort to avoid it. "the language you're interacting with" | `/prepositions` |
| Plurals never take an apostrophe: "APIs", not "API's" | `/pluralization` |
| Never pluralise a unit abbreviation: "64 GB", not "64 GBs" | `/pluralization` |
| Never write "key(s)". Use "one or more keys" | `/pluralization` |
| "one or more" takes a plural verb; "more than one" takes a singular | `/pluralization` |
| Class and type names stay singular: "`Intent` objects", not "`Intent`s" | `/pluralization` |
| Never form a possessive on a code identifier — rewrite. Not "`wordCount`'s return value" but "the value returned by `wordCount`" | `/possessives` |
| Products and trademarks take no possessive: "Google Search performance" | `/possessives` |
| Spell an abbreviation out on first use, both forms italic. Capitalise the spelled-out form only if it is a proper noun: "data manipulation language (DML)" | `/abbreviations` |
| No periods in acronyms | `/abbreviations` |

### Capitalisation — `/capitalization`

- **Sentence case** for headings, captions, list items, table content, glossary
  terms. First word, first word after a colon, proper nouns.
- Headings never end in a period.
- Don't capitalise for emphasis or to mark a special meaning.
- Avoid all-caps and camelCase outside official names and code.
- Don't use the jargon "camel case" or "snake case" — show the pattern with an
  example.

---

## What this adds over `patterns.md`

`patterns.md` catches slop vocabulary and slop structure. This file catches
things that list has no entry for at all:

- anthropomorphism
- floating "this" and "it"
- *i.e.* / *e.g.*
- passive voice, **with its three legitimate exceptions**
- dropped articles
- curly quotes and the `…` character
- possessives on code identifiers
- abbreviations used as verbs
- sentence case in headings

Where the two agree — "in order to" → "to", the throat-clear, the Oxford comma
being fine — cite this file. A rule beats a hunch when he pushes back.

One place they may conflict: `patterns.md` § Rhythm says no sentence over thirty
words. Google has no such rule, and his reflective register runs long on purpose.
Treat the thirty-word line as a docs-register heuristic, not a law.

---

## Structure and components

Docs register only. Every rule in this section is for reference material with
many readers and many authors; see the guard above before applying any of it to
a post.

### Headings — `/headings`

- **Sentence case.** Always.
- **A task heading starts with a bare infinitive**: "Create an instance", not
  "Creating an instance".
- **A conceptual heading is a noun phrase that does not start with `-ing`**:
  "Migration to Google Cloud", not "Migrating to Google Cloud". Established nouns
  like "Billing" and "Pricing" are fine.
- One level-1 heading per page, and it is unique across the doc set.
- Never skip a level — no h3 without an h2.
- No empty headings: a heading is followed by content.
- No links inside a heading. No numbering to imply sequence.
- "Keep punctuation simple. Punctuation can be a sign that your heading is too
  complicated." *(The guide does not actually forbid a trailing period or a
  question mark in a heading — that rule comes from `/capitalization`, and only
  for the period.)*

### Paragraphs — `/paragraph-structure`

- One idea per paragraph. Longer than five or six sentences usually means two
  ideas, though a genuinely single-idea paragraph may run long.
- **Do not lengthen sentences to reduce the sentence count.** "Use shorter
  sentences and paragraphs."
- Front-load the important information. **Docs only** — see the guard.
- Left-align. Never centre, justify, or right-align. No hard line breaks
  mid-paragraph.

### Lists — `/lists`

- Parallel construction across items.
- Capitalise the first word, unless case carries meaning.
- **Punctuate items, with four exceptions** — no terminal punctuation when the
  item is a single word, has no verb, is entirely code font, or is entirely link
  text or a title.
- **A one-item list is not a list.** Use prose.
- Introduce with a *complete* sentence, not a fragment the items finish. Colon
  when the list follows immediately, period otherwise. A list under a heading
  that already frames it needs no lead-in.

### Notices — `/notices`

**A closed set of four**, and the type is the meaning:

| Type | Means |
|---|---|
| Note | An aside or tip. Useful, not critical |
| Caution | Proceed carefully |
| Warning | Don't do this, or this may be irreversible |
| Success | A successful action or error-free state. Interactive content only |

- Too many notices and they stop being distinct.
- **Never stack them.** A note containing a caution, or three warnings in a row,
  means the section needs reorganising.
- **A Note is the wrong component** for a cross-reference, a prerequisite, a
  procedural step, necessary information, or anything that flows naturally in the
  surrounding prose. Its qualifying condition is that the content is *not* part
  of the flow.

### Procedures — `/procedures`

- A one-step procedure is a **bulleted** item, not a numbered list of one.
- One action per step.
- **The first sentence of a step contains an imperative verb.**
- Optional steps start with the literal word `Optional:`, not `(Optional)`.
- Say where the action happens before saying to do it. Say the goal before the
  action.
- Steps are complete sentences.
- **The result stays in the same paragraph as the action** — an outcome is not a
  new step and not a note.
- Sub-steps use a, b, c; sub-sub-steps use lowercase roman.

### Tables — `/tables`

**When a table is the wrong shape**, which is the useful half of this page:

- one item, one row, or one column → a list or prose
- code snippets → a code block
- a long one-dimensional list split into columns → a list
- anywhere inside a numbered procedure
- page layout → CSS

Headers are sentence case and **take no terminal punctuation** — no period, no
ellipsis, no colon. Mark them up as real headers with a `scope`; styling alone
does not make a header row. **Never merge cells** — no `colspan`, no `rowspan`.
Sort rows logically, or alphabetically when there is no logical order.

### Cross-references and link text — `/cross-references`

- **Link text has to make sense on its own.** Never "click here", "this
  document", "this article".
- **Never use a bare URL as link text.** Use the page title or a description.
  (Legal documents are the one carve-out.)
- Front-load the meaningful words. Don't reuse the same link text for two
  different targets in one page.
- The house phrasing is "For more information, see …" — and "about", never "on".

### Footnotes — `/footnotes`

**Avoid them.** The guide's stated reasons are accessibility and localisation.
In order of preference, replace one with: a cross-reference, a Note, or a
parenthetical. A real footnote is a last resort.

### Code in running text — `/code-in-text`

- Code font: attribute, class, method, package, namespace and data-type names;
  filenames; environment variables; command output; port numbers; HTTP status
  codes.
- Ordinary font: domain names, IP addresses, product and service names, URLs
  meant to be navigated to.
- The literal command is code (`gcc`); the product it stands for is not (GCC).
- **Never inflect a code term.** Add a real noun and inflect that instead: not
  "`ADDRESS`'s value" but "the `ADDRESS` constant's value".
- Don't wrap code in quotation marks unless the quotes are part of the code.
- Call them **status codes** — not response codes, not error codes: "an HTTP
  `400 Bad Request` status code".

### Placeholders and command-line syntax — `/placeholders`, `/code-syntax`

- Placeholders are `UPPERCASE_WITH_UNDERSCORES`. Not `api-name`, not `apiName`.
- No possessive adjectives in a placeholder: not `MY_API_NAME`.
- Never `x` or `xx` as a generic placeholder, except in status-code ranges where
  it is the convention.
- Optional argument → `[square brackets]`. Mutually exclusive → `{a|b}`.
  Repeatable → `...` with no spaces.
- Always follow a command with a list describing its placeholders.
- Show output only when there is something to copy or verify. Introduce it with
  "The output is similar to the following:".
- **Omitted code in a sample is a comment in that language, never `...` and never
  the ellipsis character.**

### Images — `/images`

- The test for alt text: replacing every image with its `alt` should not change
  the meaning of the page.
- Never open alt text with "Image of" or "Photo of".
- 155 characters. If it needs more, summarise in `alt` and describe in the body.
- Decorative images take `alt=""`.
- A caption is not alt text and does not replace it. Format: `Figure N. Description.`
- SVG for diagrams, PNG fallback. No transparent backgrounds. **No animated GIFs
  — use MP4.**
- Screenshots: crop tight, no visible PII (cover with a solid block, never a blur
  or mosaic), and never bake explanatory text into the image.

### Filenames — `/filenames`

Lowercase, hyphens not underscores, ASCII only. In prose, the filename is code
font followed by the literal word "file". Name a file by its format, not its
extension: "a PNG file", not "a `.png` file".

### API reference comments — `/api-reference-comments`

Present tense. Don't repeat the class name in its own first sentence and don't
write "this class does…". The verb is fixed by the method's kind: **Gets** /
**Sets** / **Updates** / **Deletes** / **Checks whether** / **Creates** /
**Called by**. Parameters are capitalised and end in a period. Booleans read
"True if …; false otherwise." Exceptions start "If …" or "Thrown when …". A
deprecation says what to use instead **and** what the reader must change.

### Examples — `/examples`

`example.com` / `.org` / `.net`. Phone numbers only in 800-555-0100 to
800-555-0199. IPs from RFC 5737 and RFC 3849. **Never `foo`, `bar`, `baz`** —
example names must mean something.

---

## Not in this guide

**Error messages and HTTP status-code guidance are not part of
developers.google.com/style.** That material lives in a separate resource,
`developers.google.com/tech-writing/error-messages`. Don't cite it as `/style/…`.

---

## Words, tone, and time

### Verified word-list entries

**Only entries confirmed against the live page are listed.** A research pass on
this word list had its fetch fabricate dozens of plausible-looking entries in the
U–Z range, so anything not below is *unverified rather than absent* — check the
page before claiming Google bans a word.

| Word | Rule |
|---|---|
| please | Don't use when explaining how to use a product, even for a hard task |
| just | Usually filler. Delete it |
| easy, easily | "What might be easy for you might not be easy for others." Cut the word |
| simply | Where a real comparison is meant, use *just* instead |
| allow, allows | Don't use. **"lets you"** |
| execute | Use **run** |
| kill | Use *stop*, *exit*, *cancel*, *end* |
| abort | Same — *stop*, *exit*, *cancel*, *end* |
| leverage | Avoid where you mean *use* |
| in order to | **to** |
| access (verb) | *see*, *edit*, *find*, *use*, *view* |
| comprise | *consist of*, *contain*, *include* |
| desire, desired | *want* or *need* |
| agnostic | *platform-independent* |
| e.g. | **for example** |
| i.e. | **that is** |
| etc. | Avoid; be specific |
| and/or | Avoid outside space-constrained tables |
| as (meaning *because*) | Use **because** |
| may | Reserve for policy and legal |
| might | Possibility, uncertain outcome |
| can | Permission and ability |
| could | Avoid. Use *can* |

**Not confirmed either way**, and left out deliberately: *robust*, *seamless*,
*powerful*, *utilize*, *obviously*, *of course*, *note that*, *we*,
*ensure/insure/assure*. `patterns.md` covers several on its own authority, which
is fine — just don't cite Google for them.

### Tense and time — `/tense`, `/timeless-documentation`, `/future`

- **Present tense.** "The server sends an acknowledgment", not "will send".
- Future tense only for genuinely later or asynchronous action — never for how a
  feature will work after the next release.
- Avoid hypothetical *would*: "If you send an unsubscribe message, the server
  removes you", not "the server would then remove you".
- **Strip anything that anchors the page to a moment**: *currently, now, new,
  newer, soon, latest, as of this writing, eventually, at present, presently,
  old, older, does not yet, existing, in the future*. "The emulator supports the
  following filters", not "now supports".
  Exempt: blog posts, release notes, anything timestamped.
- Never pre-announce an unreleased feature.

### Tone — `/tone`, `/text-formatting`

- Avoid exclamation points in general.
- **"Wackiness, zaniness, and goofiness"** — avoid.
- **Bold is for UI elements and run-in headings only.** This structurally forbids
  bold as an emphasis tic, which is one of the LLM formatting tells.
- Italics: introducing or defining a term, emphasis, titles of full works, math
  and version variables. Sparingly.
- Underline: link text, nothing else.
- Ampersand is never a conjunction in prose.

### Person — `/person`

Second person, "you". Imperative mood for instructions. Third person for what the
software does. *We/our/us* only for the organisation speaking. **Docs only** —
this is first on the guard list above.

---

## What this catches, and what it does not

Worth being straight about, because the overlap is narrower than the pitch
suggests. Google's guide optimises against **bureaucratic hedging, imprecision,
and untranslatable idiom**. LLM prose fails a different way: it is fluent,
balanced, and over-made.

**It catches:** anthropomorphism · floating "this" · *i.e.*/*e.g.* · passive
voice · *just*, *simply*, *easy*, *please*, *allows you to* · *in order to* ·
bold as an emphasis tic · time-anchoring throat-clears · dropped articles ·
curly quotes.

**It does not catch, and has no rule for:** the tricolon · "not just X but Y" ·
em-dash density · balanced hedging · the concluding summary that restates the
body · the engineered aphorism · abstract elegance · "X, not Y".

That second list is `patterns.md` § Structural and `writing-voice.md` §
"Claude's tells", and it stays the harder half. **Passing every rule in this file
does not mean a piece is free of slop.** They test different things.
