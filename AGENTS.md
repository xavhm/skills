# AGENTS.md

This repo is a collection of agent skills, installed into other projects with `npx skills add xavhm/skills`. Every skill lives in `skills/<name>/SKILL.md` or, grouped by category, in `skills/<category>/<name>/SKILL.md` (frontmatter with `name` and `description`). Only one category level is discovered, and skill names must be unique across categories.

There are two kinds of skills:

- **Personal**: written here, edited freely.
- **Vendored**: copied from a third-party repo with `scripts/skills.sh`. Never edit them by hand, the next update overwrites the changes.

## Rules

- Do not run `npx skills add` inside this repo: it installs into `.agents/` and `.claude/`, which `npx skills` cannot discover as a source.
- To add a third-party skill: `scripts/skills.sh <owner/repo | git-url> <skill> [category]`. It copies the skill into `skills/[<category>/]<skill>/` and updates the table below.
- To update all third-party skills: `scripts/skills.sh` (no arguments). It re-vendors every skill listed in the table below, in its recorded category.
- To move a vendored skill to another category, re-run the add command with the new category.
- To remove a skill, vendored or personal: `scripts/remove.sh <skill>`. It deletes the skill in whatever category it lives (and the category folder if it ends up empty) and its row in the table below. Do not delete vendored skills by hand, a leftover row would bring them back on the next update.
- To add a personal skill: create `skills/[<category>/]<name>/SKILL.md`. Do not add it to the table below.

## Vendored skills

Updated by `scripts/skills.sh`, do not edit by hand.

| Skill | Category | Source | Path in source | Commit | Date |
| ----- | -------- | ------ | -------------- | ------ | ---- |
| `modern-web-guidance` | software-engineering | googlechrome/modern-web-guidance | `skills/modern-web-guidance` | `b31dc0a` | 2026-10-14 |
| `feature-sliced-design` | software-engineering | feature-sliced/skills | `feature-sliced-design` | `5e95aae` | 2026-10-14 |
| `shadcn-vue` | software-engineering | unovue/shadcn-vue | `skills/shadcn-vue` | `b251d9f` | 2026-10-14 |
| `pinia` | software-engineering | antfu/skills | `skills/pinia` | `feb0f3a` | 2026-10-14 |
| `pinia-colada` | software-engineering | secondsky/claude-skills | `plugins/pinia-colada/skills/pinia-colada` | `8837836` | 2026-10-14 |
| `vue-router-best-practices` | software-engineering | vuejs-ai/skills | `skills/vue-router-best-practices` | `c9d355f` | 2026-10-14 |
| `vue-testing-best-practices` | software-engineering | vuejs-ai/skills | `skills/vue-testing-best-practices` | `c9d355f` | 2026-10-14 |
| `vue-best-practices` | software-engineering | vuejs-ai/skills | `skills/vue-best-practices` | `c9d355f` | 2026-10-14 |
| `no-ai-slop` | content | petergyang/no-ai-slop | `skills/no-ai-slop` | `000650b` | 2026-10-14 |
| `grill-me` | engineering-workflow | mattpocock/skills | `skills/productivity/grill-me` | `49dd158` | 2026-10-14 |
| `grilling` | engineering-workflow | mattpocock/skills | `skills/productivity/grilling` | `49dd158` | 2026-10-14 |
| `handoff` | engineering-workflow | mattpocock/skills | `skills/productivity/handoff` | `49dd158` | 2026-10-14 |
| `code-review` | engineering-workflow | mattpocock/skills | `skills/engineering/code-review` | `49dd158` | 2026-10-14 |
| `codebase-design` | engineering-workflow | mattpocock/skills | `skills/engineering/codebase-design` | `49dd158` | 2026-10-14 |
| `domain-modeling` | engineering-workflow | mattpocock/skills | `skills/engineering/domain-modeling` | `49dd158` | 2026-10-14 |
| `grill-with-docs` | engineering-workflow | mattpocock/skills | `skills/engineering/grill-with-docs` | `49dd158` | 2026-10-14 |
| `implement` | engineering-workflow | mattpocock/skills | `skills/engineering/implement` | `49dd158` | 2026-10-14 |
| `improve-codebase-architecture` | engineering-workflow | mattpocock/skills | `skills/engineering/improve-codebase-architecture` | `49dd158` | 2026-10-14 |
| `setup-matt-pocock-skills` | engineering-workflow | mattpocock/skills | `skills/engineering/setup-matt-pocock-skills` | `49dd158` | 2026-10-14 |
| `tdd` | engineering-workflow | mattpocock/skills | `skills/engineering/tdd` | `49dd158` | 2026-10-14 |
| `to-spec` | engineering-workflow | mattpocock/skills | `skills/engineering/to-spec` | `49dd158` | 2026-10-14 |
| `to-tickets` | engineering-workflow | mattpocock/skills | `skills/engineering/to-tickets` | `49dd158` | 2026-10-14 |
| `triage` | engineering-workflow | mattpocock/skills | `skills/engineering/triage` | `49dd158` | 2026-10-14 |
| `wayfinder` | engineering-workflow | mattpocock/skills | `skills/engineering/wayfinder` | `49dd158` | 2026-10-14 |
| `prototype` | engineering-workflow | mattpocock/skills | `skills/engineering/prototype` | `49dd158` | 2026-10-14 |
| `animate` | frontend-engineering | emilkowalski/skills | `skills/animate` | `2d22863` | 2026-10-14 |
| `animation-performance` | frontend-engineering | emilkowalski/skills | `skills/animation-performance` | `2d22863` | 2026-10-14 |
| `improve-animations` | frontend-engineering | emilkowalski/skills | `skills/improve-animations` | `2d22863` | 2026-10-14 |
| `find-animation-opportunities` | frontend-engineering | emilkowalski/skills | `skills/find-animation-opportunities` | `2d22863` | 2026-10-14 |
<!-- vendored:end -->
