#!/bin/sh
# test_detect.sh - Detection logic tests

# ---------------------------------------------------------------------------
# Helper: run detection in a fixture directory
# ---------------------------------------------------------------------------
detect_in_fixture() {
    _fixture="$1"
    _orig_dir="$(pwd)"
    cd "$SCRIPT_DIR/fixtures/$_fixture"
    run_detection
    cd "$_orig_dir"
}

# ---------------------------------------------------------------------------
# Next.js project detection
# ---------------------------------------------------------------------------
printf "\n  ${YELLOW}Next.js project${RESET}\n"
detect_in_fixture "nextjs-project"

assert_eq "typescript" "$DETECTED_LANGUAGE" "detects TypeScript"
assert_eq "nextjs" "$DETECTED_FRAMEWORK" "detects Next.js framework"
assert_eq "pnpm" "$DETECTED_PKG_MANAGER" "detects pnpm"
assert_eq "vitest" "$DETECTED_TEST_FRAMEWORK" "detects vitest"
assert_eq "eslint" "$DETECTED_LINTER" "detects eslint"
assert_eq "prettier" "$DETECTED_FORMATTER" "detects prettier"
assert_eq "my-nextjs-app" "$DETECTED_PROJECT_NAME" "detects project name from package.json"
assert_eq "A Next.js application" "$DETECTED_DESCRIPTION" "detects description from package.json"
assert_contains "$DETECTED_CMD_BUILD" "build" "detects build command"
assert_contains "$DETECTED_CMD_DEV" "dev" "detects dev command"
assert_contains "$DETECTED_CMD_TEST" "test" "detects test command"

# ---------------------------------------------------------------------------
# Python FastAPI project detection
# ---------------------------------------------------------------------------
printf "\n  ${YELLOW}Python FastAPI project${RESET}\n"
detect_in_fixture "python-api"

assert_eq "python" "$DETECTED_LANGUAGE" "detects Python"
assert_eq "fastapi" "$DETECTED_FRAMEWORK" "detects FastAPI framework"
assert_eq "uv" "$DETECTED_PKG_MANAGER" "detects uv"
assert_eq "pytest" "$DETECTED_TEST_FRAMEWORK" "detects pytest"
assert_eq "ruff" "$DETECTED_LINTER" "detects ruff linter"
assert_eq "ruff" "$DETECTED_FORMATTER" "detects ruff formatter"
assert_eq "my-fastapi-app" "$DETECTED_PROJECT_NAME" "detects project name from pyproject.toml"

# ---------------------------------------------------------------------------
# Go CLI project detection
# ---------------------------------------------------------------------------
printf "\n  ${YELLOW}Go CLI project${RESET}\n"
detect_in_fixture "go-cli"

assert_eq "go" "$DETECTED_LANGUAGE" "detects Go"
assert_eq "go" "$DETECTED_PKG_MANAGER" "detects go module"
assert_eq "go test" "$DETECTED_TEST_FRAMEWORK" "detects go test"
assert_eq "golangci-lint" "$DETECTED_LINTER" "detects golangci-lint"
assert_eq "gofmt" "$DETECTED_FORMATTER" "detects gofmt"
assert_eq "my-go-cli" "$DETECTED_PROJECT_NAME" "detects project name from go.mod"
assert_contains "$DETECTED_CMD_BUILD" "go build" "detects go build command"
assert_contains "$DETECTED_CMD_TEST" "go test" "detects go test command"

# ---------------------------------------------------------------------------
# Rust CLI project detection
# ---------------------------------------------------------------------------
printf "\n  ${YELLOW}Rust CLI project${RESET}\n"
detect_in_fixture "rust-cli"

assert_eq "rust" "$DETECTED_LANGUAGE" "detects Rust"
assert_eq "cargo" "$DETECTED_PKG_MANAGER" "detects cargo"
assert_eq "cargo test" "$DETECTED_TEST_FRAMEWORK" "detects cargo test"
assert_eq "clippy" "$DETECTED_LINTER" "detects clippy"
assert_eq "rustfmt" "$DETECTED_FORMATTER" "detects rustfmt"
assert_eq "my-rust-cli" "$DETECTED_PROJECT_NAME" "detects project name from Cargo.toml"
assert_contains "$DETECTED_CMD_BUILD" "cargo build" "detects cargo build command"

# ---------------------------------------------------------------------------
# Empty project detection
# ---------------------------------------------------------------------------
printf "\n  ${YELLOW}Empty project${RESET}\n"
detect_in_fixture "empty-project"

assert_eq "" "$DETECTED_LANGUAGE" "no language detected in empty project"
assert_eq "" "$DETECTED_FRAMEWORK" "no framework detected in empty project"
assert_eq "" "$DETECTED_PKG_MANAGER" "no pkg manager detected in empty project"
