#!/bin/sh
# core.sh - Colors, menus, confirm(), json helpers, platform detection
# POSIX-compliant, zero dependencies

# ---------------------------------------------------------------------------
# Platform detection
# ---------------------------------------------------------------------------
detect_platform() {
    OS="$(uname -s)"
    case "$OS" in
        Darwin*)  PLATFORM="macos" ;;
        Linux*)   PLATFORM="linux" ;;
        MINGW*|MSYS*|CYGWIN*) PLATFORM="windows" ;;
        *)        PLATFORM="unknown" ;;
    esac
    export PLATFORM
}

# ---------------------------------------------------------------------------
# Color / formatting helpers (auto-disable when not a TTY)
# ---------------------------------------------------------------------------
setup_colors() {
    if [ -t 1 ] && [ -t 0 ]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        BLUE='\033[0;34m'
        MAGENTA='\033[0;35m'
        CYAN='\033[0;36m'
        BOLD='\033[1m'
        DIM='\033[2m'
        RESET='\033[0m'
        HAS_COLOR=1
    else
        RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN=''
        BOLD='' DIM='' RESET=''
        HAS_COLOR=0
    fi
    export RED GREEN YELLOW BLUE MAGENTA CYAN BOLD DIM RESET HAS_COLOR
}

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------
info()    { printf "${BLUE}info${RESET}  %s\n" "$1"; }
success() { printf "${GREEN}ok${RESET}    %s\n" "$1"; }
warn()    { printf "${YELLOW}warn${RESET}  %s\n" "$1"; }
error()   { printf "${RED}error${RESET} %s\n" "$1" >&2; }
header()  { printf "\n${BOLD}${CYAN}==> %s${RESET}\n\n" "$1"; }
dim()     { printf "${DIM}%s${RESET}\n" "$1"; }

# ---------------------------------------------------------------------------
# Input helpers
# ---------------------------------------------------------------------------

# read_input PROMPT [DEFAULT]
# Prints prompt, reads a line, echoes default if blank
read_input() {
    _prompt="$1"
    _default="${2:-}"
    if [ -n "$_default" ]; then
        printf "%s ${DIM}[%s]${RESET}: " "$_prompt" "$_default"
    else
        printf "%s: " "$_prompt"
    fi
    read -r _answer </dev/tty
    if [ -z "$_answer" ]; then
        printf '%s' "$_default"
    else
        printf '%s' "$_answer"
    fi
}

# confirm PROMPT [default y|n]
# Returns 0 for yes, 1 for no
confirm() {
    _prompt="$1"
    _default="${2:-y}"
    if [ "$_default" = "y" ]; then
        _hint="Y/n"
    else
        _hint="y/N"
    fi
    printf "%s ${DIM}[%s]${RESET}: " "$_prompt" "$_hint"
    read -r _answer </dev/tty
    _answer="$(printf '%s' "$_answer" | tr '[:upper:]' '[:lower:]')"
    case "$_answer" in
        y|yes) return 0 ;;
        n|no)  return 1 ;;
        "")
            if [ "$_default" = "y" ]; then return 0; else return 1; fi
            ;;
        *) return 1 ;;
    esac
}

# numbered_menu TITLE OPTION1 OPTION2 ... OPTIONn
# Sets MENU_CHOICE to the selected value, MENU_INDEX to 1-based index
# Returns 0 on valid selection
numbered_menu() {
    _title="$1"
    shift
    _count=0
    _items=""

    # Store items
    for _item in "$@"; do
        _count=$(( _count + 1 ))
        _items="$_items|$_item"
    done

    printf "\n%s\n" "$_title"
    _i=0
    for _item in "$@"; do
        _i=$(( _i + 1 ))
        printf "  ${CYAN}%d${RESET}) %s\n" "$_i" "$_item"
    done
    printf "\n"

    while true; do
        printf "Choose ${DIM}[1-%d]${RESET}: " "$_count"
        read -r _choice </dev/tty
        # Validate numeric
        case "$_choice" in
            ''|*[!0-9]*)
                warn "Please enter a number between 1 and $_count"
                continue
                ;;
        esac
        if [ "$_choice" -ge 1 ] && [ "$_choice" -le "$_count" ] 2>/dev/null; then
            MENU_INDEX="$_choice"
            # Get the nth item
            _i=0
            for _item in "$@"; do
                _i=$(( _i + 1 ))
                if [ "$_i" -eq "$_choice" ]; then
                    MENU_CHOICE="$_item"
                    break
                fi
            done
            return 0
        else
            warn "Please enter a number between 1 and $_count"
        fi
    done
}

# multi_select TITLE OPTION1 OPTION2 ... OPTIONn
# Sets MULTI_CHOICES as pipe-delimited string of selected values
multi_select() {
    _title="$1"
    shift
    _count=0

    printf "\n%s ${DIM}(space-separated numbers, or 'all')${RESET}\n" "$_title"
    _i=0
    for _item in "$@"; do
        _i=$(( _i + 1 ))
        _count=$_i
        printf "  ${CYAN}%d${RESET}) %s\n" "$_i" "$_item"
    done
    printf "\n"

    printf "Choose: "
    read -r _choices </dev/tty

    MULTI_CHOICES=""
    case "$_choices" in
        all|ALL|a|A)
            for _item in "$@"; do
                if [ -z "$MULTI_CHOICES" ]; then
                    MULTI_CHOICES="$_item"
                else
                    MULTI_CHOICES="$MULTI_CHOICES|$_item"
                fi
            done
            ;;
        *)
            for _num in $_choices; do
                # Validate
                case "$_num" in
                    ''|*[!0-9]*) continue ;;
                esac
                if [ "$_num" -ge 1 ] && [ "$_num" -le "$_count" ] 2>/dev/null; then
                    _i=0
                    for _item in "$@"; do
                        _i=$(( _i + 1 ))
                        if [ "$_i" -eq "$_num" ]; then
                            if [ -z "$MULTI_CHOICES" ]; then
                                MULTI_CHOICES="$_item"
                            else
                                MULTI_CHOICES="$MULTI_CHOICES|$_item"
                            fi
                            break
                        fi
                    done
                fi
            done
            ;;
    esac
}

# ---------------------------------------------------------------------------
# JSON helpers (no jq needed)
# ---------------------------------------------------------------------------

# json_string VALUE
# Escapes a string for safe JSON embedding, outputs with surrounding quotes
json_string() {
    _val="$1"
    # Escape backslashes first, then double quotes, then control characters
    _val="$(printf '%s' "$_val" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/	/\\t/g')"
    # Handle newlines
    _val="$(printf '%s' "$_val" | tr '\n' ' ')"
    printf '"%s"' "$_val"
}

# json_array ITEM1 ITEM2 ...
# Outputs a JSON array of strings
json_array() {
    printf '['
    _first=1
    for _item in "$@"; do
        if [ "$_first" -eq 1 ]; then
            _first=0
        else
            printf ', '
        fi
        json_string "$_item"
    done
    printf ']'
}

# json_object_start
json_object_start() { printf '{\n'; }

# json_kv KEY VALUE [last]
# Outputs "key": "value", (omit trailing comma if 3rd arg is "last")
json_kv() {
    _key="$1"
    _value="$2"
    _last="${3:-}"
    printf '  %s: %s' "$(json_string "$_key")" "$(json_string "$_value")"
    if [ "$_last" = "last" ]; then
        printf '\n'
    else
        printf ',\n'
    fi
}

# json_kv_raw KEY RAW_VALUE [last]
# Outputs "key": raw_value (for arrays, objects, booleans)
json_kv_raw() {
    _key="$1"
    _raw="$2"
    _last="${3:-}"
    printf '  %s: %s' "$(json_string "$_key")" "$_raw"
    if [ "$_last" = "last" ]; then
        printf '\n'
    else
        printf ',\n'
    fi
}

# json_object_end
json_object_end() { printf '}\n'; }

# ---------------------------------------------------------------------------
# File helpers
# ---------------------------------------------------------------------------

# backup_file PATH
# Creates PATH.bak.TIMESTAMP if PATH exists
backup_file() {
    _path="$1"
    if [ -f "$_path" ]; then
        _ts="$(date +%Y%m%d%H%M%S)"
        _backup="${_path}.bak.${_ts}"
        cp "$_path" "$_backup"
        info "Backed up $(basename "$_path") -> $(basename "$_backup")"
    fi
}

# ensure_dir PATH
# Creates directory if it doesn't exist
ensure_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

# write_file PATH CONTENT
# Writes content to file, creating parent dirs as needed
write_file() {
    _path="$1"
    _content="$2"
    ensure_dir "$(dirname "$_path")"
    printf '%s\n' "$_content" > "$_path"
}

# ---------------------------------------------------------------------------
# String helpers
# ---------------------------------------------------------------------------

# contains HAYSTACK NEEDLE
# Returns 0 if haystack contains needle (pipe-delimited list)
contains() {
    _haystack="$1"
    _needle="$2"
    case "|${_haystack}|" in
        *"|${_needle}|"*) return 0 ;;
        *) return 1 ;;
    esac
}

# to_lower STRING
to_lower() {
    printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

# trim STRING
trim() {
    _str="$1"
    _str="${_str#"${_str%%[![:space:]]*}"}"
    _str="${_str%"${_str##*[![:space:]]}"}"
    printf '%s' "$_str"
}

# ---------------------------------------------------------------------------
# Initialization
# ---------------------------------------------------------------------------
core_init() {
    detect_platform
    setup_colors
}
