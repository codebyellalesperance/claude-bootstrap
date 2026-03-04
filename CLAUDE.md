# Claude Bootstrap -- Claude Code Project Instructions

## Project Overview

Claude Bootstrap is a zero-dependency POSIX shell installer that bootstraps Claude Code configuration for any project. One command generates a tailored CLAUDE.md, .claude/settings.json, and optional skill files based on auto-detected stack.

## Absolute Rules

- NEVER use emojis anywhere in the project. No emojis in code, comments, commit messages, documentation, UI strings, error messages, logs, or any other output. This is non-negotiable.
- NEVER use emojis in commit messages, branch names, PR titles, or PR descriptions.
- NEVER add emojis to any file in this repository.
- POSIX sh only -- no bash-isms (`[[ ]]`, arrays, `local`, process substitution).
- Zero external dependencies -- no jq, python, node, or other tools.

## Stack

- Pure POSIX sh (no bash, no zsh)
- shellcheck for linting
- GitHub Actions for CI/CD
- No runtime dependencies

## Project Structure

```
claude-bootstrap/
  CLAUDE.md                          -- this file
  install.sh                         -- entry point (sources lib/ or runs embedded)
  build.sh                           -- concatenates lib/ + templates/ into dist/install.sh
  lib/
    core.sh                          -- colors, menus, JSON helpers, platform detection
    detect.sh                        -- auto-detect language, framework, tooling
    prompts.sh                       -- interactive 5-phase CLI prompt flow
    generate.sh                      -- template composition and file generation
    preview.sh                       -- preview output before writing
  templates/
    claude-md/
      frameworks/                    -- 10 framework convention templates
      languages/                     -- 8 language convention templates
      sections/                      -- 6 CLAUDE.md section templates
    settings/
      base.json                      -- base .claude/settings.json template
    skills/                          -- 6 pre-built skill templates
  tests/
    test_runner.sh                   -- POSIX test harness
    test_detect.sh                   -- detection logic tests
    test_generate.sh                 -- output generation tests
    test_install.sh                  -- installation integration tests
    fixtures/                        -- test fixture projects
  dist/                              -- (gitignored) built single-file distributable
  .github/workflows/
    ci.yml                           -- shellcheck + tests on Ubuntu and macOS
    release.yml                      -- tag-triggered release with dist artifact
```

## Git and GitHub

### Repository

- Remote: Push all work to GitHub (public repo).
- Always ensure the remote is set before pushing.

### Branch Naming

```
<type>/<short-description>
```

Types: `feat/`, `fix/`, `refactor/`, `chore/`, `docs/`, `test/`, `perf/`, `style/`

Examples:
- `feat/detect-phoenix-framework`
- `fix/posix-printf-escaping`
- `test/add-ruby-detection-fixtures`
- `chore/ci-shellcheck-version-bump`

### Commit Messages

Follow Conventional Commits. No emojis. Format:

```
<type>(<scope>): <short summary>

<optional body -- explain WHY, not WHAT>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `style`

Scopes: `detect`, `generate`, `templates`, `core`, `build`, `test`, `ci`

Examples:
- `feat(detect): add Phoenix framework detection via mix.exs`
- `fix(core): escape percent signs in printf format strings`
- `test(detect): add Go CLI fixture and detection assertions`
- `chore(ci): pin shellcheck to v0.10.0`

Rules:
- Subject line max 72 characters
- Use imperative mood
- Do not end subject with a period
- Body should explain the reasoning, not restate the diff
- Always include the Co-Authored-By trailer

## Code Style

- POSIX sh only -- test with `shellcheck lib/*.sh install.sh build.sh`
- Use pipe-delimited lists for multi-value variables (e.g., `"react|vue|svelte"`)
- Prefix internal helper functions with underscore (e.g., `_detect_language`)
- No external dependencies -- everything must work with a bare POSIX shell
- Quote all variable expansions
- Use `printf` over `echo` for portable output

## Key Commands

```bash
sh install.sh                    # run interactive installer from repo
sh build.sh                      # build single-file dist/install.sh
sh tests/test_runner.sh          # run full test suite
shellcheck lib/*.sh install.sh   # lint all shell files
```

## Supported Stacks

**Languages (8):** TypeScript, JavaScript, Python, Go, Rust, Java, Ruby, C#
**Frameworks (10):** Next.js, React, Vue, Svelte, Express, FastAPI, Django, Rails, Gin, Spring
**Package managers:** npm, yarn, pnpm, bun, pip, uv, cargo, go modules, bundler
**Test frameworks:** jest, vitest, pytest, go test, cargo test
**Linters:** ESLint, Prettier, Ruff, golangci-lint, clippy

## Development Workflow

1. Add detection pattern in `lib/detect.sh`
2. Add conventions in `lib/generate.sh`
3. Add template fragment in `templates/claude-md/`
4. Add test fixture in `tests/fixtures/`
5. Add tests in `tests/test_detect.sh` or `tests/test_generate.sh`
6. Run tests: `sh tests/test_runner.sh`
7. Run shellcheck: `shellcheck lib/*.sh install.sh build.sh`
8. Build: `sh build.sh`
9. Test the built artifact: `sh dist/install.sh`
10. Commit with conventional commit format
