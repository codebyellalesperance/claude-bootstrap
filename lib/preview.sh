#!/bin/sh
# preview.sh - Show user what will be generated before writing
# POSIX-compliant, zero dependencies

# ---------------------------------------------------------------------------
# Preview all files that will be generated
# ---------------------------------------------------------------------------
show_preview() {
    header "Phase 5: Preview"

    printf "The following files will be created:\n\n"

    # CLAUDE.md preview
    _claude_md="$(generate_claude_md)"
    _claude_lines="$(printf '%s' "$_claude_md" | wc -l | tr -d ' ')"
    printf "  ${GREEN}create${RESET}  CLAUDE.md (%s lines)\n" "$_claude_lines"

    # .claude/settings.json preview
    _settings="$(generate_settings_json)"
    _settings_lines="$(printf '%s' "$_settings" | wc -l | tr -d ' ')"
    printf "  ${GREEN}create${RESET}  .claude/settings.json (%s lines)\n" "$_settings_lines"

    # Skills preview
    if [ -n "$SELECTED_SKILLS" ]; then
        _OLD_IFS="$IFS"
        IFS="|"
        for _skill_entry in $SELECTED_SKILLS; do
            _skill_cmd="$(printf '%s' "$_skill_entry" | sed 's/ -.*//' | sed 's|^/||')"
            if [ -n "$_skill_cmd" ]; then
                _skill_content="$(generate_skill "$_skill_cmd")"
                _skill_lines="$(printf '%s' "$_skill_content" | wc -l | tr -d ' ')"
                printf "  ${GREEN}create${RESET}  .claude/skills/%s.md (%s lines)\n" "$_skill_cmd" "$_skill_lines"
            fi
        done
        IFS="$_OLD_IFS"
    fi

    printf "\n"

    # Show CLAUDE.md content preview
    if confirm "Show CLAUDE.md preview?"; then
        printf "\n${DIM}--- CLAUDE.md ---${RESET}\n"
        printf '%s\n' "$_claude_md"
        printf "${DIM}--- end ---${RESET}\n\n"
    fi

    # Show settings preview
    if confirm "Show settings.json preview?" "n"; then
        printf "\n${DIM}--- .claude/settings.json ---${RESET}\n"
        printf '%s\n' "$_settings"
        printf "${DIM}--- end ---${RESET}\n\n"
    fi

    # Final confirmation
    if ! confirm "Write these files?"; then
        info "Cancelled. No files were written."
        return 1
    fi

    return 0
}
