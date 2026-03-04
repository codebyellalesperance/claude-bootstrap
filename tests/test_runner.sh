#!/bin/sh
# test_runner.sh - POSIX-compatible test harness
# Usage: sh tests/test_runner.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Colors (minimal)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    BOLD='\033[1m'
    RESET='\033[0m'
else
    GREEN='' RED='' YELLOW='' BOLD='' RESET=''
fi

# ---------------------------------------------------------------------------
# Test assertion helpers
# ---------------------------------------------------------------------------

# assert_eq EXPECTED ACTUAL MESSAGE
assert_eq() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if [ "$1" = "$2" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        printf "  ${GREEN}PASS${RESET} %s\n" "$3"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf "  ${RED}FAIL${RESET} %s\n" "$3"
        printf "    expected: '%s'\n" "$1"
        printf "    actual:   '%s'\n" "$2"
    fi
}

# assert_ne VALUE1 VALUE2 MESSAGE
assert_ne() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if [ "$1" != "$2" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        printf "  ${GREEN}PASS${RESET} %s\n" "$3"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf "  ${RED}FAIL${RESET} %s\n" "$3"
        printf "    values should differ but both are: '%s'\n" "$1"
    fi
}

# assert_contains HAYSTACK NEEDLE MESSAGE
assert_contains() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    case "$1" in
        *"$2"*)
            TESTS_PASSED=$((TESTS_PASSED + 1))
            printf "  ${GREEN}PASS${RESET} %s\n" "$3"
            ;;
        *)
            TESTS_FAILED=$((TESTS_FAILED + 1))
            printf "  ${RED}FAIL${RESET} %s\n" "$3"
            printf "    '%s' not found in output\n" "$2"
            ;;
    esac
}

# assert_not_contains HAYSTACK NEEDLE MESSAGE
assert_not_contains() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    case "$1" in
        *"$2"*)
            TESTS_FAILED=$((TESTS_FAILED + 1))
            printf "  ${RED}FAIL${RESET} %s\n" "$3"
            printf "    '%s' should not be in output\n" "$2"
            ;;
        *)
            TESTS_PASSED=$((TESTS_PASSED + 1))
            printf "  ${GREEN}PASS${RESET} %s\n" "$3"
            ;;
    esac
}

# assert_file_exists PATH MESSAGE
assert_file_exists() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if [ -f "$1" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        printf "  ${GREEN}PASS${RESET} %s\n" "$2"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf "  ${RED}FAIL${RESET} %s\n" "$2"
        printf "    file not found: %s\n" "$1"
    fi
}

# assert_exit_code EXPECTED_CODE COMMAND MESSAGE
assert_exit_code() {
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    _expected="$1"
    shift
    _msg="$1"
    shift
    if eval "$@" >/dev/null 2>&1; then
        _actual=0
    else
        _actual=$?
    fi
    if [ "$_actual" -eq "$_expected" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        printf "  ${GREEN}PASS${RESET} %s\n" "$_msg"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf "  ${RED}FAIL${RESET} %s\n" "$_msg"
        printf "    expected exit code %d, got %d\n" "$_expected" "$_actual"
    fi
}

# ---------------------------------------------------------------------------
# Run test files
# ---------------------------------------------------------------------------
run_test_file() {
    _file="$1"
    _name="$(basename "$_file" .sh)"
    printf "\n${BOLD}%s${RESET}\n" "$_name"
    . "$_file"
}

# Source library files for testing
. "$PROJECT_DIR/lib/core.sh"
. "$PROJECT_DIR/lib/detect.sh"
. "$PROJECT_DIR/lib/generate.sh"
. "$PROJECT_DIR/lib/preview.sh"

# Initialize core (non-interactive - no TTY colors)
setup_colors

printf "\n${BOLD}claude-bootstrap test suite${RESET}\n"
printf "═══════════════════════════\n"

# Run each test file
for _test_file in "$SCRIPT_DIR"/test_*.sh; do
    _basename="$(basename "$_test_file")"
    # Don't run ourselves
    if [ "$_basename" = "test_runner.sh" ]; then continue; fi
    run_test_file "$_test_file"
done

# Summary
printf "\n═══════════════════════════\n"
printf "Total: %d  " "$TESTS_TOTAL"
printf "${GREEN}Passed: %d${RESET}  " "$TESTS_PASSED"
if [ "$TESTS_FAILED" -gt 0 ]; then
    printf "${RED}Failed: %d${RESET}" "$TESTS_FAILED"
else
    printf "Failed: 0"
fi
printf "\n\n"

if [ "$TESTS_FAILED" -gt 0 ]; then
    exit 1
fi
exit 0
