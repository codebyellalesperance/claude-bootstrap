#!/bin/sh
# Template: Testing section for CLAUDE.md

tmpl_section_testing() {
    _framework="$1"
    _tdd="$2"
    _lang="$3"
    _cmd_test="$4"

    [ -z "$_framework" ] && [ "$_tdd" = "none" ] && return

    printf '## Testing\n\n'
    [ -n "$_framework" ] && printf -- '- **Framework**: %s\n' "$_framework"

    case "$_tdd" in
        strict)    printf -- '- **TDD**: Write tests FIRST. Follow red-green-refactor.\n' ;;
        alongside) printf -- '- Write tests alongside implementation\n' ;;
        after)     printf -- '- Write tests after implementation to verify behavior\n' ;;
    esac

    case "$_lang" in
        typescript|javascript) printf -- '- Test files: `*.test.ts` / `*.test.tsx`\n' ;;
        python)                printf -- '- Test files: `test_*.py` in `tests/`\n' ;;
        go)                    printf -- '- Test files: `*_test.go` colocated with source\n' ;;
        rust)                  printf -- '- Unit tests in `#[cfg(test)]` modules; integration in `tests/`\n' ;;
    esac

    [ -n "$_cmd_test" ] && printf -- '- Run: `%s`\n' "$_cmd_test"
    printf '\n'
}
