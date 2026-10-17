# Agent Skills

Repo skills live under `.agents/skills/*/SKILL.md`. An agent matches the task against the skill `name` and
`description`, then loads the full instructions only when it matches.

## Available Repo Skills

- `localization`: hardcoded UI text scans, ARB updates, locale generation, and localization verification.
- `ui-work`: Flutter UI, widgets, Material You styling, navigation surfaces, async feedback, and user-facing interactions.
- `core-platform`: Core lifecycle/process ownership, Android services, Go event delivery, desktop IPC, platform managers,
  VPN/TUN, and Windows Helper flow.
- `pre-commit-quality-review`: lightweight triage before commits, with scoped structural review and user decisions on concrete regressions.

## Authoring Notes

- Add new repeatable workflows as `.agents/skills/<skill-name>/SKILL.md`; remove the directory when retiring a skill.
- Keep skill descriptions trigger-focused and start them with `Use when...`.
- Keep long reference material in `.agents/*.md`; skills should link to it instead of duplicating it.
