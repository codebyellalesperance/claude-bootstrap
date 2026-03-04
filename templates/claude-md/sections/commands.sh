#!/bin/sh
# Template: Common commands section for CLAUDE.md

tmpl_section_commands() {
    _build="$1"
    _dev="$2"
    _test="$3"
    _lint="$4"
    _format="$5"

    _has_cmd=0
    for _c in "$_build" "$_dev" "$_test" "$_lint" "$_format"; do
        [ -n "$_c" ] && _has_cmd=1 && break
    done
    [ "$_has_cmd" -eq 0 ] && return

    printf '## Common Commands\n\n'
    printf '```sh\n'
    [ -n "$_build" ]  && printf '# Build\n%s\n\n' "$_build"
    [ -n "$_dev" ]    && printf '# Dev server\n%s\n\n' "$_dev"
    [ -n "$_test" ]   && printf '# Run tests\n%s\n\n' "$_test"
    [ -n "$_lint" ]   && printf '# Lint\n%s\n\n' "$_lint"
    [ -n "$_format" ] && printf '# Format\n%s\n' "$_format"
    printf '```\n\n'
}
