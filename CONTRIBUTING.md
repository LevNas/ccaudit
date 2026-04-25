# Contributing to ccaudit

Thanks for taking an interest in ccaudit! This short guide explains the project's focus and how to contribute effectively.

## Project Focus

ccaudit is a **Claude Code plugin** that captures audit trails of AI-assisted work and pushes them to a remote trail repository. To keep the plugin small and predictable, it stays within these boundaries:

- The `Stop` hook (`hooks/auto-flush.sh`) and the `/audit-flush` skill — both implementing the same auto-flush flow
- The bundled secret-pattern list — vendor-neutral generic patterns only, see [Vendor neutrality](#vendor-neutrality)
- Trail entry format spec, audit-side operating guide, and the secret-pattern catalog (`docs/`)
- Test fixtures and the end-to-end smoke test (`test/`)

### Vendor neutrality

The bundled secret-pattern list in `hooks/auto-flush.sh` ships in a public repository. It must remain free of organization-specific token prefixes, internal hostnames, customer names, or proprietary token formats. If your environment uses such patterns, layer them on with `CCAUDIT_PRE_FLUSH_HOOK` instead — see [docs/extending.md](docs/extending.md).

PRs that add organization-specific patterns to `hooks/auto-flush.sh` or `docs/secret-patterns.md` will be rejected. This isn't a personal preference; it's the property that lets ccaudit ship publicly without leaking operational detail from any one user's environment.

### Adapting ccaudit for Other Use Cases

Ideas like porting ccaudit to other AI assistants, building a different audit-side workflow, integrating with a SIEM, or adding compliance-regime-specific scoring are interesting — but they go beyond what this repository aims to provide.

If you'd like to explore those directions, **forking ccaudit and adapting it freely is very much encouraged**. The MIT License gives you full permission to do so, and a credit link back to this project is appreciated (see [License](README.md#license)).

If you're not sure whether your idea fits the project's focus, feel free to open an issue with the `question` label first — we can discuss it before you invest time in a PR.

## Plugin Conventions

ccaudit follows the LevNas plugin conventions maintained in [claudecode-plugins/docs/development-guide.md](https://github.com/LevNas/claudecode-plugins/blob/main/docs/development-guide.md). Document placement is summarized here.

| Location | Purpose | Audience |
|----------|---------|----------|
| `README.md` | Plugin overview and usage | Users (humans) |
| `skills/<name>/SKILL.md` | Skill definition with required frontmatter | Claude Code |
| `skills/<name>/procedure.md` | Detailed procedure followed by the skill | Claude Code |
| `hooks/` | Hook implementations | Claude Code |
| `docs/` | Developer/operator internal docs (trail format, secret-pattern catalog, audit-side guide, roadmap, extending guide) | Contributors (humans) |
| `test/` | Fixtures and end-to-end smoke test | Contributors (humans) |

### Smoke test

Run the smoke test before any PR that touches the hook, the skill, or the secret-pattern list:

```bash
bash test/smoke-test.sh
```

The script asserts both the clean-flush path and the secret-blocked path against a throwaway local bare repository. It uses no external network or credentials. New patterns should not break either assertion, and new code paths should add their own assertions.

### Updating secret patterns

When adding or modifying a regex in `hooks/auto-flush.sh`, **also update `docs/secret-patterns.md` in the same commit** (the catalog is the source of truth for rationale and example shapes; the hook is the source of truth for runtime behavior). PRs that touch only one of them will be sent back for the other.

## Pull Request Guidelines

To make review smooth for everyone:

1. **Open an issue first** for changes beyond typo fixes or small documentation tweaks. This avoids wasted work and helps align on direction early.
2. **Keep PRs focused** — one logical change per PR makes review much easier.
3. **Update documentation** (`README.md`, `docs/`, `SKILL.md`) when your change affects user-facing behavior.
4. **Run the smoke test** (`bash test/smoke-test.sh`) and match the tone of the surrounding Markdown.
5. **By submitting a PR**, you agree that your contribution will be licensed under the same MIT License as the rest of the project.

## Attribution When Forking

ccaudit is MIT licensed, so you're free to fork, modify, and redistribute it. The MIT License requires that you keep the copyright notice and license text in copies or substantial portions of the software.

Beyond that, if you build something based on ccaudit, a credit line in your README is appreciated:

> Based on [ccaudit](https://github.com/LevNas/ccaudit) by LevNas.

This isn't a license condition — just a friendly request that helps users trace the lineage of ideas.

## Questions

For anything that isn't a bug report or feature proposal, the `question` issue template is the right place.
