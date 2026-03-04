#!/bin/sh
# claude-bootstrap - Set up Claude Code configuration for any project
# https://github.com/claude-bootstrap/claude-bootstrap
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<user>/claude-bootstrap/main/install.sh | sh
#   # or
#   git clone ... && cd claude-bootstrap && ./install.sh
#
# POSIX-compliant, zero dependencies

set -e

# Wrap everything in main() to prevent partial execution when piped
main() {

    # ---------------------------------------------------------------------------
    # Resolve script location for sourcing lib/ files
    # ---------------------------------------------------------------------------
    SCRIPT_DIR=""
    RUNNING_FROM_REPO=0

    # Try to find the lib directory relative to this script
    if [ -n "${BASH_SOURCE:-}" ]; then
        _self="$BASH_SOURCE"
    elif [ -n "$0" ] && [ "$0" != "sh" ] && [ "$0" != "-sh" ] && [ "$0" != "/bin/sh" ]; then
        _self="$0"
    else
        _self=""
    fi

    if [ -n "$_self" ] && [ -f "$_self" ]; then
        _dir="$(cd "$(dirname "$_self")" && pwd)"
        if [ -f "$_dir/lib/core.sh" ]; then
            SCRIPT_DIR="$_dir"
            RUNNING_FROM_REPO=1
        fi
    fi

    # ---------------------------------------------------------------------------
    # Source library files or use embedded functions
    # ---------------------------------------------------------------------------
    if [ "$RUNNING_FROM_REPO" -eq 1 ]; then
        . "$SCRIPT_DIR/lib/core.sh"
        . "$SCRIPT_DIR/lib/detect.sh"
        . "$SCRIPT_DIR/lib/prompts.sh"
        . "$SCRIPT_DIR/lib/generate.sh"
        . "$SCRIPT_DIR/lib/preview.sh"
    else
        # When running via curl pipe, all functions should be embedded by build.sh
        # If they're not embedded, we need to download them
        if ! command -v core_init >/dev/null 2>&1; then
            echo "Error: This script must be run from the cloned repository,"
            echo "or use the built single-file version."
            echo ""
            echo "  git clone https://github.com/<user>/claude-bootstrap.git"
            echo "  cd claude-bootstrap && ./install.sh"
            exit 1
        fi
    fi

    # ---------------------------------------------------------------------------
    # Initialize
    # ---------------------------------------------------------------------------
    core_init

    printf "\n"
    printf "${BOLD}${CYAN}"
    printf '  ╔═══════════════════════════════════════╗\n'
    printf '  ║        claude-bootstrap               ║\n'
    printf '  ║   Claude Code project configurator    ║\n'
    printf '  ╚═══════════════════════════════════════╝\n'
    printf "${RESET}\n"

    # ---------------------------------------------------------------------------
    # Run interactive prompt flow
    # ---------------------------------------------------------------------------
    if ! run_prompts; then
        exit 1
    fi

    # ---------------------------------------------------------------------------
    # Preview and confirm
    # ---------------------------------------------------------------------------
    if ! show_preview; then
        exit 0
    fi

    # ---------------------------------------------------------------------------
    # Write files
    # ---------------------------------------------------------------------------
    write_all_files

    printf "\n"
    printf "${BOLD}${GREEN}"
    printf '  ✓ Claude Code configuration complete!\n'
    printf "${RESET}\n"
    printf "  Files created:\n"
    printf "    - CLAUDE.md\n"
    printf "    - .claude/settings.json\n"
    if [ -n "$SELECTED_SKILLS" ]; then
        printf "    - .claude/skills/ (custom skills)\n"
    fi
    printf "\n"
    printf "  ${DIM}Run 'claude' in this directory to get started.${RESET}\n"
    printf "\n"
}

main "$@"
