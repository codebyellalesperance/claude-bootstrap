# Changelog

## [0.1.0] - 2026-03-02

### Added
- Initial release
- Interactive CLI prompt flow (5 phases)
- Auto-detection for: TypeScript, JavaScript, Python, Go, Rust, Java, Ruby, C#
- Framework detection: Next.js, React, Vue, Svelte, Express, FastAPI, Django, Rails, Gin, Spring, and more
- Package manager detection: npm, yarn, pnpm, bun, uv, poetry, pip, cargo, go, maven, gradle, bundler
- Test framework detection: vitest, jest, pytest, go test, cargo test, rspec, junit
- Linter/formatter detection: eslint, prettier, biome, ruff, black, golangci-lint, clippy, rubocop
- CLAUDE.md generation with tailored sections
- .claude/settings.json with safe permission defaults
- Skill generation: /review, /test, /fix-issue, /deploy, /tdd, /document, /component, /endpoint
- Build script for single-file distribution
- POSIX sh compatible (no bash required)
- Test suite with detection, generation, and integration tests
- GitHub Actions CI (shellcheck + tests on Ubuntu and macOS)
