# skills

[![skills.sh](https://img.shields.io/badge/skills.sh-compatible-black)](https://skills.sh)
[![Agents](https://img.shields.io/badge/agents-Claude%20%7C%20Codex%20%7C%20Cursor%20%7C%20more-blue)](https://github.com/vercel-labs/skills)
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

Personal collection of [agent skills](https://github.com/vercel-labs/skills), installable into any project with `npx skills`.

## Usage

List the available skills:

```bash
npx skills add xavhm/skills --list
```

Install one or more into the current project:

```bash
npx skills add xavhm/skills --skill <skill-name>
```

Target a specific agent, or install globally:

```bash
npx skills add xavhm/skills --skill <skill-name> --agent claude-code
npx skills add xavhm/skills --skill <skill-name> --global
```

Update installed skills:

```bash
npx skills update
```

## Adding skills

Every skill lives in `skills/<name>/SKILL.md`, or grouped in one category folder: `skills/<category>/<name>/SKILL.md` (e.g. `software-engineering`, `productivity`). This is the only place `npx skills` discovers skills from this repo. Skill names must be unique across categories.

### Personal skills

Create `skills/<name>/SKILL.md` (frontmatter: `name` + `description`), commit, push.

### Third-party skills

Third-party skills are vendored with a script, because `npx skills add` installs into `.agents/` / `.claude/`, which can't be used as a source.

**Add one:**

```bash
scripts/vendor.sh <owner/repo | git-url> <skill> [category]
# e.g. scripts/vendor.sh googlechrome/modern-web-guidance modern-web-guidance software-engineering
```

It copies the skill into `skills/[<category>/]<skill>/` and adds its source, category, path, commit and date to the table in [AGENTS.md](AGENTS.md). Review with `git diff`, then commit. To move a skill to another category, re-run the command with the new one.

**Update all:**

```bash
scripts/vendor.sh
```

It re-fetches every skill listed in `AGENTS.md`, in its recorded category, and refreshes their rows.

The `AGENTS.md` table is maintained by the script, and vendored skills are overwritten on update, so don't edit either by hand.
