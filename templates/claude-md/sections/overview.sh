#!/bin/sh
# Template: Project overview section for CLAUDE.md

tmpl_section_overview() {
    _name="${1:?project name required}"
    _desc="${2:-}"
    printf '# %s\n\n' "$_name"
    if [ -n "$_desc" ]; then
        printf '%s\n\n' "$_desc"
    fi
}
