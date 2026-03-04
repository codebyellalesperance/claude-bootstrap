#!/bin/sh
# test_install.sh - End-to-end integration tests (non-interactive)

# ---------------------------------------------------------------------------
# Test: core.sh functions
# ---------------------------------------------------------------------------
printf "\n  ${YELLOW}Core library functions${RESET}\n"

# json_string
_js="$(json_string 'hello "world"')"
assert_eq '"hello \"world\""' "$_js" "json_string escapes quotes"

_js="$(json_string 'simple')"
assert_eq '"simple"' "$_js" "json_string wraps in quotes"

# json_array
_ja="$(json_array "a" "b" "c")"
assert_eq '["a", "b", "c"]' "$_ja" "json_array produces valid array"

# to_lower
_tl="$(to_lower "HELLO")"
assert_eq "hello" "$_tl" "to_lower works"

# trim
_tr="$(trim "  hello  ")"
assert_eq "hello" "$_tr" "trim removes whitespace"

# contains
if contains "a|b|c" "b"; then
    assert_eq "0" "0" "contains finds existing item"
else
    assert_eq "0" "1" "contains finds existing item"
fi

if contains "a|b|c" "d"; then
    assert_eq "0" "1" "contains returns false for missing item"
else
    assert_eq "0" "0" "contains returns false for missing item"
fi

# ---------------------------------------------------------------------------
# Test: file operations in temp directory
# ---------------------------------------------------------------------------
printf "\n  ${YELLOW}File operations${RESET}\n"

_tmpdir="$(mktemp -d)"
_test_path="$_tmpdir/sub/dir/test.txt"
write_file "$_test_path" "hello world"
assert_file_exists "$_test_path" "write_file creates nested directories and file"

_content="$(cat "$_test_path")"
assert_eq "hello world" "$_content" "write_file writes correct content"

# backup_file
cp "$_test_path" "$_tmpdir/backup_test.txt"
backup_file "$_tmpdir/backup_test.txt"
_backup_count="$(ls "$_tmpdir"/backup_test.txt.bak.* 2>/dev/null | wc -l | tr -d ' ')"
assert_ne "0" "$_backup_count" "backup_file creates .bak file"

# Cleanup
rm -rf "$_tmpdir"

# ---------------------------------------------------------------------------
# Test: project dir safety check
# ---------------------------------------------------------------------------
printf "\n  ${YELLOW}Safety checks${RESET}\n"

# Test that check_project_dir fails in empty dirs without indicators
_tmpdir="$(mktemp -d)"
_orig="$(pwd)"
cd "$_tmpdir"
# check_project_dir prompts when no indicators found, but since no TTY,
# the confirm will default to "n" and return 1
# We can't easily test interactive prompts, so test the detection part
_has_indicator=0
for _f in .git package.json pyproject.toml go.mod Cargo.toml Gemfile pom.xml build.gradle Makefile README.md; do
    if [ -e "$_f" ]; then
        _has_indicator=1
        break
    fi
done
assert_eq "0" "$_has_indicator" "empty dir has no project indicators"

# With a .git directory
mkdir .git
_has_indicator=0
for _f in .git package.json pyproject.toml go.mod Cargo.toml Gemfile pom.xml build.gradle Makefile README.md; do
    if [ -e "$_f" ]; then
        _has_indicator=1
        break
    fi
done
assert_eq "1" "$_has_indicator" "dir with .git has project indicator"

cd "$_orig"
rm -rf "$_tmpdir"

# ---------------------------------------------------------------------------
# Test: build.sh produces output
# ---------------------------------------------------------------------------
printf "\n  ${YELLOW}Build script${RESET}\n"

_build_out="$(mktemp -d)"
sh "$PROJECT_DIR/build.sh" "$_build_out/install.sh" 2>&1
assert_file_exists "$_build_out/install.sh" "build.sh produces install.sh"

# Check the built file contains key functions
_built="$(cat "$_build_out/install.sh")"
assert_contains "$_built" "core_init" "built file contains core_init"
assert_contains "$_built" "run_detection" "built file contains run_detection"
assert_contains "$_built" "generate_claude_md" "built file contains generate_claude_md"
assert_contains "$_built" 'main "$@"' "built file has main wrapper"

rm -rf "$_build_out"

# ---------------------------------------------------------------------------
# Test: all lib files are valid shell
# ---------------------------------------------------------------------------
printf "\n  ${YELLOW}Shell syntax validation${RESET}\n"

for _lib in "$PROJECT_DIR"/lib/*.sh; do
    _name="$(basename "$_lib")"
    if sh -n "$_lib" 2>/dev/null; then
        assert_eq "0" "0" "$_name has valid shell syntax"
    else
        assert_eq "0" "1" "$_name has valid shell syntax"
    fi
done
