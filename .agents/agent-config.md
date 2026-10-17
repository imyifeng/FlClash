# Agent Configuration Model

Use the smallest durable surface that matches the job.

## Surfaces

- `AGENTS.md`: repository entry point. Keep it small and reserve it for always-on rules, routing, and high-priority expectations.
- `.agents/*.md`: human- and agent-readable reference docs linked from `AGENTS.md`. Use these for detailed project context, commands, architecture, and conventions.
- `.agents/skills/*/SKILL.md`: repo skills. Use these for repeatable workflows that should be discoverable by name and description.

## Placement Rules

- Put stable team conventions in `AGENTS.md` only when every task must see them without opening another file.
- Put detailed explanations in `.agents/*.md` and link them from `AGENTS.md`.
- Put reusable task workflows in `.agents/skills/<skill-name>/SKILL.md`.
- Put mechanical enforcement in linters, tests, or hooks; do not rely on prose when tooling can enforce the rule.
- Split a rule into the part that can be counted and the part that cannot, and enforce them differently. A rule resting entirely on judgment gets decided at the keyboard, at the moment the exception looks most justified; the comment policy is the worked example, where "is this comment useful" stays prose and review while "are these comments too frequent" became a measured gate. Find the countable half before writing more prose.
- Restate the one-line form of a rule in every context that must obey it, and keep its explanation in one `.agents/*.md` file that the others link to. Prefer a runnable check to either: a gate an agent trips before reporting done outperforms a paragraph asking it to have been careful.
- State a gate's real force. Enforcement differs per tool, and a rule that claims uniform coverage it does not have is worse than one that names the gap.
- Keep user-specific preferences out of the repository. They belong in user-level tool configuration or user-level skills.

## Skill Authoring Rules

- Use lowercase hyphenated names.
- Start descriptions with `Use when...`.
- Describe trigger conditions in the description, not the workflow.
- Keep `SKILL.md` lean; link to `.agents/*.md` for large reference material.
- Add scripts only when deterministic behavior is needed repeatedly.
