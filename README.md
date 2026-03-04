# claude-bootstrap

Set up [Claude Code](https://docs.anthropic.com/en/docs/claude-code) configuration for any project in seconds.

Run one command, answer a few prompts, get a tailored `CLAUDE.md` + `.claude/` config generated automatically.

## Quick Start

```sh
# From your project directory:
git clone https://github.com/<user>/claude-bootstrap.git /tmp/claude-bootstrap
/tmp/claude-bootstrap/install.sh
```

Or clone and run:

```sh
git clone https://github.com/<user>/claude-bootstrap.git
cd claude-bootstrap
./install.sh    # run from your project directory
```

## What It Does

1. **Detects** your project stack (language, framework, package manager, tooling)
2. **Asks** a few questions about your preferences (confirms auto-detected values)
3. **Generates** tailored configuration files:
   - `CLAUDE.md` - Project context for Claude (40-80 lines, specific to your stack)
   - `.claude/settings.json` - Safe permission defaults
   - `.claude/skills/` - Custom slash commands (/review, /test, /tdd, etc.)

## Supported Stacks

| Languages | Frameworks | Tooling |
|-----------|-----------|---------|
| TypeScript | Next.js, React, Vue, Svelte, Angular | eslint, prettier, biome |
| JavaScript | Express, Fastify, Hono | vitest, jest, playwright |
| Python | FastAPI, Django, Flask | pytest, ruff, black |
| Go | Gin, Echo, Chi, Fiber | golangci-lint, go test |
| Rust | Actix, Axum, Rocket | clippy, cargo test |
| Java | Spring Boot | JUnit, Maven, Gradle |
| Ruby | Rails, Sinatra | RSpec, RuboCop |
| C# | - | dotnet |

## Interactive Flow

The installer walks through 5 quick phases:

1. **Safety Checks** - Verifies project directory, backs up existing config
2. **Project Basics** - Confirms detected stack, project name, description
3. **Conventions** - Test framework, linter, formatter, TDD preference, commands
4. **Git Workflow** - Commit style, branching strategy, skills selection
5. **Preview & Write** - Shows exactly what will be created, confirms before writing

## Generated Output

### CLAUDE.md

A concise, tailored project context file that includes:
- Project overview and tech stack
- Common commands (build, dev, test, lint, format)
- Language-specific coding conventions
- Framework-specific best practices
- Testing instructions and preferences
- Git workflow guidelines

### .claude/settings.json

Safe permission defaults:
- Allows detected build/test/lint commands
- Denies reading `.env*`, secrets, credentials
- Denies destructive commands

### .claude/skills/

Pre-built slash commands you can select:
- `/review` - Code review with specific criteria
- `/test` - Run tests and analyze failures
- `/fix-issue` - Fix a GitHub issue by number
- `/deploy` - Pre-deployment checklist
- `/tdd` - Red-green-refactor cycle
- `/document` - Generate documentation
- `/component` - Create UI component (web projects)
- `/endpoint` - Create API endpoint (API projects)

## Development

```sh
# Run tests
sh tests/test_runner.sh

# Build single-file distributable
sh build.sh

# Check shell syntax
shellcheck lib/*.sh install.sh build.sh
```

## Design Principles

- **POSIX `/bin/sh`** - No bash-isms. Works on macOS, Linux, WSL, CI containers
- **Zero dependencies** - No jq, node, python. Pure shell
- **Curl-pipe safe** - Wrapped in `main() { ... }; main "$@"`
- **Idempotent** - Safe to re-run; backs up existing files
- **Non-destructive** - Always previews before writing, offers backup

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## License

[MIT](LICENSE)
