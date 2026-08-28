---
name: writing-skills
description: >-
  Writes and revises agent skills. Use when deciding whether something should be a skill, a
  rule, or a hook, when a skill is not firing or never triggers when asked for, when creating a
  skill or editing a SKILL.md, or when writing or fixing a skill description.
---

# Writing skills

A skill is a description plus a body. The description decides whether the skill runs. The body decides
what happens once it does. Almost every failed skill failed at the description.

## Does this need to be a skill

State what the model does **without** the skill. If the answer is "roughly the same thing," there is no
skill, and writing one produces a file that never fires.

This is not a stylistic preference. Measured across 22 skills and 11 months of one developer's usage,
every skill that fired named an activity the model would not otherwise perform — rewriting prose into a
specific voice, an API reference, an open-source audit, a session ritual. Every skill that never fired
restated default behavior: one to run tests, one to search, one to debug, one to plan. Trigger evals
confirmed it later: a skill named `research` would not fire on a prompt beginning with the word
"research", and one named `qa` would not fire on "can you QA the app."

The model already runs tests, reads code, searches the web, debugs errors, and plans work. A skill that
tells it to do those things is a no-op wearing a filename.

Pick the mechanism before writing anything:

| Need | Use |
|---|---|
| Knowledge or a procedure the model lacks | Skill |
| A constraint that applies to a set of files | Path-scoped rule |
| Something that must happen every time, no exceptions | Hook |
| A long verbose search whose output should not reach the main context | Subagent |

Rules and skills are advice; the model can ignore them. Only a hook is enforcement.

## Descriptions

The description is written for the model, not for a person browsing the repo. It is the only part
loaded before the skill runs, and it is matched against what the user actually typed.

**Model-invoked** — the skill should fire on its own:

```
<what it does>. Use when <2-4 trigger phrases, in the words a user would actually type>.
```

Third person. Never "I can help you." The trigger phrases matter more than the summary: write the words
that get typed, not the words that describe the category.

One skill's description said it made prose "sound like Sameer." It did not fire on "make this sound
more like me" — the model was being asked to resolve an identity it had no reason to connect. Adding
the literal phrasings, including "less like ChatGPT," fixed it. Quote the user, not yourself.

**User-invoked** — `disable-model-invocation: true`, only ever run as a slash command. One line, no
"Use when" clause, written for a human reading a list. It costs no context, and the human has to
remember it exists.

Default to model-invoked. Typed slash commands were 2.2% of prompts in the measured sample.

## Frontmatter

`name` and `description` only. Add `allowed-tools` only where it genuinely restricts — a read-only
skill that must not write. Listing the tools the skill would get anyway is noise.

## Body

Under 500 lines. Overflow goes to a reference file beside the skill, exactly one level deep: a skill
that points at a file that points at another file gets partially read, and the model will `head` it
rather than follow the chain.

Inline what every run needs. Push behind a pointer what only some runs reach.

Every step needs a completion criterion the model can check. "Be thorough" is not one. "Every exported
function has a test" is.

## Evals

Three cases minimum, in `evals/<name>.jsonl`, at least one negative:

```json
{"prompt": "make this blog post sound less like ChatGPT", "expect": "deslop"}
{"prompt": "add a retry to the fetch call", "expect": null}
```

Run `./scripts/eval.sh <name>`. A skill that will not fire is not a skill.

Read the failures correctly:

- **Undertriggering** — add the phrasings that were actually typed. Do not touch the body.
- **Overtriggering** — narrow the "Use when" clause and add the negative case that caught it.
- **Fires but does badly** — that is the body. The description is fine; leave it alone.
- **The case is wrong** — check this first. Two of the three failures in the first run across seven
  skills were bad cases, not bad descriptions.

Write cases as tasks, not questions. A description can match a prompt almost verbatim and still not
fire: "should this be a skill or a hook?" did not trigger a skill whose description led with
"deciding whether something should be a skill, a rule, or a hook," because it is a question the model
can simply answer. "Write me a skill for reviewing migrations" fires. The model weighs whether it
needs the skill at all, which is the no-op rule seen from the other side.

Trigger phrases displace each other. Adding one to a description broke a case that had been passing;
reordering so the failing phrase led fixed both. Reorder before you add, and re-run the whole file
rather than the failing case.

Two skills whose names collide will split the routing between them. If a skill stops firing after an
edit, check that nothing else in `skills/` answers to the same triggers.

## What goes wrong

- **Negation.** "Don't write tests first" activates the idea it bans. State the positive instead. Keep
  prohibitions for hard guardrails only.
- **Restating the environment.** A skill that repeats what `package.json` scripts or `--help` already
  say is a cache that goes stale. Point at the source.
- **Sediment.** Skills accumulate because adding feels safe and deleting feels risky. A skill with no
  invocations in 90 days is deleted, not archived — an unused skill still costs description tokens in
  every session, and a stale one competes for triggers with a live one.
- **Writing for the reader.** A description that reads well in the repo and never fires is a failure.
