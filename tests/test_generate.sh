#!/bin/sh
# test_generate.sh - Output generation tests

# ---------------------------------------------------------------------------
# Test CLAUDE.md generation for a TypeScript/Next.js project
# ---------------------------------------------------------------------------
printf "\n  ${YELLOW}CLAUDE.md generation - Next.js${RESET}\n"

# Set up variables as if user went through prompts
PROJECT_NAME="my-nextjs-app"
DESCRIPTION="A Next.js application"
LANGUAGE="typescript"
FRAMEWORK="nextjs"
PKG_MANAGER="pnpm"
TEST_FRAMEWORK="vitest"
LINTER="eslint"
FORMATTER="prettier"
CMD_BUILD="pnpm build"
CMD_DEV="pnpm dev"
CMD_TEST="pnpm test"
CMD_LINT="pnpm lint"
CMD_FORMAT="pnpm format"
COMMIT_STYLE="conventional"
BRANCH_STRATEGY="github-flow"
TDD_PREFERENCE="alongside"
NAMING_CONVENTION="camelCase for variables/functions, PascalCase for classes/components"

_output="$(generate_claude_md)"

assert_contains "$_output" "# my-nextjs-app" "has project title"
assert_contains "$_output" "A Next.js application" "has description"
assert_contains "$_output" "TypeScript" "has language"
assert_contains "$_output" "Next.js" "has framework"
assert_contains "$_output" "pnpm" "has package manager"
assert_contains "$_output" "vitest" "has test framework"
assert_contains "$_output" "pnpm build" "has build command"
assert_contains "$_output" "pnpm dev" "has dev command"
assert_contains "$_output" "pnpm test" "has test command"
assert_contains "$_output" "Conventional Commits" "has commit style"
assert_contains "$_output" "feature branches" "has branching strategy"
assert_contains "$_output" "strict mode" "has TypeScript convention"
assert_contains "$_output" "Server Components" "has Next.js convention"

# ---------------------------------------------------------------------------
# Test CLAUDE.md generation for a Python/FastAPI project
# ---------------------------------------------------------------------------
printf "\n  ${YELLOW}CLAUDE.md generation - FastAPI${RESET}\n"

PROJECT_NAME="my-api"
DESCRIPTION="A FastAPI backend"
LANGUAGE="python"
FRAMEWORK="fastapi"
PKG_MANAGER="uv"
TEST_FRAMEWORK="pytest"
LINTER="ruff"
FORMATTER="ruff"
CMD_BUILD=""
CMD_DEV="uvicorn main:app --reload"
CMD_TEST="uv run pytest"
CMD_LINT="uv run ruff check ."
CMD_FORMAT="uv run ruff format ."
COMMIT_STYLE="descriptive"
BRANCH_STRATEGY="trunk"
TDD_PREFERENCE="strict"
NAMING_CONVENTION="snake_case for functions/variables"

_output="$(generate_claude_md)"

assert_contains "$_output" "# my-api" "has project title"
assert_contains "$_output" "Python" "has language"
assert_contains "$_output" "FastAPI" "has framework"
assert_contains "$_output" "pytest" "has test framework"
assert_contains "$_output" "uv run pytest" "has test command"
assert_contains "$_output" "PEP 8" "has Python convention"
assert_contains "$_output" "Pydantic" "has FastAPI convention"
assert_contains "$_output" "tests FIRST" "has TDD preference"
assert_not_contains "$_output" "# Build" "no build section for API project"

# ---------------------------------------------------------------------------
# Test settings.json generation
# ---------------------------------------------------------------------------
printf "\n  ${YELLOW}settings.json generation${RESET}\n"

PROJECT_NAME="test-project"
LANGUAGE="typescript"
PKG_MANAGER="pnpm"
CMD_BUILD="pnpm build"
CMD_TEST="pnpm test"
CMD_LINT="pnpm lint"
CMD_FORMAT=""
CMD_DEV=""

_settings="$(generate_settings_json)"

assert_contains "$_settings" '"permissions"' "has permissions key"
assert_contains "$_settings" '"allow"' "has allow list"
assert_contains "$_settings" '"deny"' "has deny list"
assert_contains "$_settings" "pnpm build" "allow list has build command"
assert_contains "$_settings" "pnpm test" "allow list has test command"
assert_contains "$_settings" ".env" "deny list has .env"
assert_contains "$_settings" "rm -rf" "deny list has rm -rf"

# ---------------------------------------------------------------------------
# Test format_framework_name
# ---------------------------------------------------------------------------
printf "\n  ${YELLOW}Framework name formatting${RESET}\n"

assert_eq "Next.js" "$(format_framework_name "nextjs")" "nextjs -> Next.js"
assert_eq "FastAPI" "$(format_framework_name "fastapi")" "fastapi -> FastAPI"
assert_eq "Spring Boot" "$(format_framework_name "spring")" "spring -> Spring Boot"
assert_eq "Rails" "$(format_framework_name "rails")" "rails -> Rails"
assert_eq "Gin" "$(format_framework_name "gin")" "gin -> Gin"
