# AGENTS.md

This repo is a collection of agent skills, installed into other projects with `npx skills add xavhm/skills`. Every skill lives in `skills/<name>/SKILL.md` or, grouped by category, in `skills/<category>/<name>/SKILL.md` (frontmatter with `name` and `description`). Only one category level is discovered, and skill names must be unique across categories.

There are two kinds of skills:

- **Personal**: written here, edited freely.
- **Vendored**: copied from a third-party repo with `scripts/vendor.sh`. Never edit them by hand, the next update overwrites the changes.

## Rules

- Do not run `npx skills add` inside this repo: it installs into `.agents/` and `.claude/`, which `npx skills` cannot discover as a source.
- To add a third-party skill: `scripts/vendor.sh <owner/repo | git-url> <skill> [category]`. It copies the skill into `skills/[<category>/]<skill>/` and updates the table below.
- To update all third-party skills: `scripts/vendor.sh` (no arguments). It re-vendors every skill listed in the table below, in its recorded category.
- To move a vendored skill to another category, re-run the add command with the new category.
- To add a personal skill: create `skills/[<category>/]<name>/SKILL.md`. Do not add it to the table below.

## Vendored skills

Updated by `scripts/vendor.sh`, do not edit by hand.

| Skill | Category | Source | Path in source | Commit | Date |
| ----- | -------- | ------ | -------------- | ------ | ---- |
| `modern-web-guidance` | software-engineering | googlechrome/modern-web-guidance | `skills/modern-web-guidance` | `b31dc0a` | 2026-10-14 |
| `feature-sliced-design` | software-engineering | feature-sliced/skills | `feature-sliced-design` | `5e95aae` | 2026-10-14 |
| `shadcn-vue` | software-engineering | unovue/shadcn-vue | `skills/shadcn-vue` | `b251d9f` | 2026-10-14 |
| `pinia` | software-engineering | antfu/skills | `skills/pinia` | `feb0f3a` | 2026-10-14 |
| `pinia-colada` | software-engineering | secondsky/claude-skills | `plugins/pinia-colada/skills/pinia-colada` | `8837836` | 2026-10-14 |
| `vue-router-best-practices` | software-engineering | vuejs-ai/skills | `skills/vue-router-best-practices` | `c9d355f` | 2026-10-14 |
| `vue-testing-best-practices` | software-engineering | vuejs-ai/skills | `skills/vue-testing-best-practices` | `c9d355f` | 2026-10-14 |
<!-- vendored:end -->
