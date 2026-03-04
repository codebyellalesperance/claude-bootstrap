#!/bin/sh
# build.sh - Concatenate lib/ + templates/ into a single distributable install.sh
# Usage: sh build.sh [output_file]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT="${1:-$SCRIPT_DIR/dist/install.sh}"

# Ensure output directory exists
mkdir -p "$(dirname "$OUTPUT")"

echo "Building single-file install.sh..."

# Start with shebang and header
cat > "$OUTPUT" << 'HEADER'
#!/bin/sh
# claude-bootstrap - Set up Claude Code configuration for any project
# https://github.com/claude-bootstrap/claude-bootstrap
#
# Install:
#   curl -fsSL https://raw.githubusercontent.com/<user>/claude-bootstrap/main/dist/install.sh | sh
#
# POSIX-compliant, zero dependencies
# Built from source - do not edit directly

set -e

main() {

HEADER

# Embed each library file (strip shebang and comments-only preamble)
for lib_file in "$SCRIPT_DIR/lib/core.sh" \
                "$SCRIPT_DIR/lib/detect.sh" \
                "$SCRIPT_DIR/lib/prompts.sh" \
                "$SCRIPT_DIR/lib/generate.sh" \
                "$SCRIPT_DIR/lib/preview.sh"; do

    _name="$(basename "$lib_file")"
    printf '\n# === %s ===\n' "$_name" >> "$OUTPUT"

    # Strip shebang line and leading comment block
    sed '1{/^#!/d;}' "$lib_file" >> "$OUTPUT"
    printf '\n' >> "$OUTPUT"
done

# Embed the main logic (the part between sourcing libs and the end)
cat >> "$OUTPUT" << 'MAIN_LOGIC'

# ---------------------------------------------------------------------------
# Initialize and run
# ---------------------------------------------------------------------------
RUNNING_FROM_REPO=0

core_init

printf "\n"
printf "${BOLD}${CYAN}"
printf '  ╔═══════════════════════════════════════╗\n'
printf '  ║        claude-bootstrap               ║\n'
printf '  ║   Claude Code project configurator    ║\n'
printf '  ╚═══════════════════════════════════════╝\n'
printf "${RESET}\n"

if ! run_prompts; then
    exit 1
fi

if ! show_preview; then
    exit 0
fi

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

MAIN_LOGIC

# Close main()
cat >> "$OUTPUT" << 'FOOTER'
}

main "$@"
FOOTER

chmod +x "$OUTPUT"

# Count lines
_lines="$(wc -l < "$OUTPUT" | tr -d ' ')"
_size="$(wc -c < "$OUTPUT" | tr -d ' ')"
_size_kb=$(( _size / 1024 ))

echo ""
echo "Built: $OUTPUT"
echo "  Lines: $_lines"
echo "  Size:  ${_size_kb}KB"
echo ""
echo "Test with:"
echo "  sh $OUTPUT"
echo "  cat $OUTPUT | sh"
