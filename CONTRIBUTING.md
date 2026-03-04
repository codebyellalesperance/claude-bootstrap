# Contributing to claude-bootstrap

## Development Setup

```sh
git clone https://github.com/<user>/claude-bootstrap.git
cd claude-bootstrap
```

## Project Structure

```
lib/           - Shell library modules (sourced by install.sh)
  core.sh      - Colors, menus, JSON helpers, platform detection
  detect.sh    - Auto-detect language, framework, tooling
  prompts.sh   - Interactive CLI prompt flow
  generate.sh  - Template composition and file generation
  preview.sh   - Preview output before writing

templates/     - Template fragments (reference, embedded during build)
tests/         - Test suite
build.sh       - Build single-file distributable
install.sh     - Entry point
```

## Guidelines

- **POSIX sh only** - No bash-isms (`[[ ]]`, arrays, `local`, process substitution)
- **Zero dependencies** - No jq, python, node, or other external tools
- **Test everything** - Add tests for new detection patterns and templates
- Run `shellcheck lib/*.sh install.sh build.sh` before submitting

## Running Tests

```sh
sh tests/test_runner.sh
```

## Adding Language/Framework Support

1. Add detection logic in `lib/detect.sh`
2. Add conventions in `lib/generate.sh` (`_lang_conventions` / `_framework_conventions`)
3. Add template fragment in `templates/claude-md/languages/` or `templates/claude-md/frameworks/`
4. Add test fixture in `tests/fixtures/`
5. Add detection tests in `tests/test_detect.sh`

## Building

```sh
sh build.sh              # outputs to dist/install.sh
sh build.sh my-output.sh # custom output path
```

## Pull Requests

- Keep changes focused and minimal
- Add tests for new functionality
- Ensure all tests pass and shellcheck is clean
- Update README if adding new supported stacks
