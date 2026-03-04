#!/bin/sh
# Template: Tech stack section for CLAUDE.md

tmpl_section_tech_stack() {
    _lang="$1"
    _framework="$2"
    _pkg="$3"
    _test="$4"
    _linter="$5"
    _formatter="$6"

    printf '## Tech Stack\n\n'
    [ -n "$_lang" ]      && printf -- '- **Language**: %s\n' "$_lang"
    [ -n "$_framework" ] && printf -- '- **Framework**: %s\n' "$_framework"
    [ -n "$_pkg" ]       && printf -- '- **Package Manager**: %s\n' "$_pkg"
    [ -n "$_test" ]      && printf -- '- **Testing**: %s\n' "$_test"
    [ -n "$_linter" ]    && printf -- '- **Linter**: %s\n' "$_linter"
    [ -n "$_formatter" ] && printf -- '- **Formatter**: %s\n' "$_formatter"
    printf '\n'
}
