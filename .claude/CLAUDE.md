# Working on this repo

Instructions for editing the kit itself. Not installed to `~/.claude`.

## Invariants

- Skill frontmatter is `name` and `description` only, unless a skill genuinely needs to restrict tools.
- Every shipped skill appears in the `README.md` table. Skills in `skills/in-progress/` do not.
- Every shipped skill has at least three cases in `evals/<name>.jsonl`, one of them negative.
- A retired skill is deleted, not archived. The commit that removes it names the replacement.
- A hook script that is not registered in `settings.template.json` does nothing. Don't add one
  without wiring it.
- `mcp/` and any `.mcp.json` contain `${VAR}` placeholders only. Never a real key.

## Writing a skill

A skill exists only if the model would not already do the thing. Before writing one, state what
happens without it. If the answer is "roughly the same," there is no skill.

Descriptions are written for the model, not for a human browsing the repo:

- Model-invoked: `"<what it does>. Use when <2-4 trigger phrases in the words the user actually
  types>."` Third person.
- User-invoked (`disable-model-invocation: true`): a one-line summary, no "Use when" clause.

Body under 500 lines. Overflow goes to a reference file exactly one level deep, never nested further.

## Prose

Factual and terse. No storytelling, no narrative openings, no motivational framing. Applies to the
README, skill bodies, and commit messages alike.
