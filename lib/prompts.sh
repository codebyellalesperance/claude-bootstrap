#!/bin/sh
# prompts.sh - Interactive CLI prompt flow (5 phases)
# POSIX-compliant, zero dependencies

# ---------------------------------------------------------------------------
# Collected configuration (set by prompts, used by generate)
# ---------------------------------------------------------------------------
PROJECT_NAME=""
DESCRIPTION=""
LANGUAGE=""
FRAMEWORK=""
PKG_MANAGER=""
TEST_FRAMEWORK=""
LINTER=""
FORMATTER=""
CMD_BUILD=""
CMD_DEV=""
CMD_TEST=""
CMD_LINT=""
CMD_FORMAT=""
COMMIT_STYLE=""
BRANCH_STRATEGY=""
TDD_PREFERENCE=""
NAMING_CONVENTION=""
SELECTED_SKILLS=""

# ---------------------------------------------------------------------------
# Phase 1: Safety Checks
# ---------------------------------------------------------------------------
phase_safety_checks() {
    header "Phase 1: Safety Checks"

    if ! check_project_dir; then
        return 1
    fi
    success "Project directory OK"

    # Check for existing CLAUDE.md
    if [ -f "CLAUDE.md" ]; then
        warn "Existing CLAUDE.md found"
        numbered_menu "What would you like to do?" \
            "Backup and overwrite" \
            "Overwrite without backup" \
            "Cancel"

        case "$MENU_INDEX" in
            1)
                backup_file "CLAUDE.md"
                OVERWRITE_MODE="backup"
                ;;
            2)
                OVERWRITE_MODE="overwrite"
                ;;
            3)
                info "Cancelled"
                return 1
                ;;
        esac
    fi

    # Check for existing .claude directory
    if [ -d ".claude" ]; then
        warn "Existing .claude/ directory found"
        if ! confirm "Merge new config into existing .claude/?"; then
            return 1
        fi
    fi

    # Run auto-detection
    info "Scanning project..."
    run_detection
    success "Detection complete"

    return 0
}

# ---------------------------------------------------------------------------
# Phase 2: Project Basics
# ---------------------------------------------------------------------------
phase_project_basics() {
    header "Phase 2: Project Basics"

    # Show and confirm detection
    if [ -n "$DETECTED_LANGUAGE" ]; then
        show_detection

        if confirm "Is this correct?"; then
            LANGUAGE="$DETECTED_LANGUAGE"
            FRAMEWORK="$DETECTED_FRAMEWORK"
            PKG_MANAGER="$DETECTED_PKG_MANAGER"
        else
            info "Let's set things up manually"
            prompt_language
            prompt_framework
            prompt_pkg_manager
        fi
    else
        warn "Could not auto-detect project stack"
        prompt_language
        prompt_framework
        prompt_pkg_manager
    fi

    # Project name and description
    PROJECT_NAME="$(read_input "Project name" "$DETECTED_PROJECT_NAME")"
    printf '\n'
    DESCRIPTION="$(read_input "One-line description" "$DETECTED_DESCRIPTION")"
    printf '\n'
}

prompt_language() {
    numbered_menu "Select primary language:" \
        "TypeScript" "JavaScript" "Python" "Go" "Rust" "Java" "Ruby" "C#"
    case "$MENU_INDEX" in
        1) LANGUAGE="typescript" ;;
        2) LANGUAGE="javascript" ;;
        3) LANGUAGE="python" ;;
        4) LANGUAGE="go" ;;
        5) LANGUAGE="rust" ;;
        6) LANGUAGE="java" ;;
        7) LANGUAGE="ruby" ;;
        8) LANGUAGE="csharp" ;;
    esac
}

prompt_framework() {
    case "$LANGUAGE" in
        typescript|javascript)
            numbered_menu "Select framework:" \
                "Next.js" "React" "Vue" "Svelte" "Express" "Fastify" "Hono" "None"
            case "$MENU_INDEX" in
                1) FRAMEWORK="nextjs" ;;
                2) FRAMEWORK="react" ;;
                3) FRAMEWORK="vue" ;;
                4) FRAMEWORK="svelte" ;;
                5) FRAMEWORK="express" ;;
                6) FRAMEWORK="fastify" ;;
                7) FRAMEWORK="hono" ;;
                8) FRAMEWORK="" ;;
            esac
            ;;
        python)
            numbered_menu "Select framework:" \
                "FastAPI" "Django" "Flask" "None"
            case "$MENU_INDEX" in
                1) FRAMEWORK="fastapi" ;;
                2) FRAMEWORK="django" ;;
                3) FRAMEWORK="flask" ;;
                4) FRAMEWORK="" ;;
            esac
            ;;
        go)
            numbered_menu "Select framework:" \
                "Gin" "Echo" "Chi" "Fiber" "None (stdlib)"
            case "$MENU_INDEX" in
                1) FRAMEWORK="gin" ;;
                2) FRAMEWORK="echo" ;;
                3) FRAMEWORK="chi" ;;
                4) FRAMEWORK="fiber" ;;
                5) FRAMEWORK="" ;;
            esac
            ;;
        ruby)
            numbered_menu "Select framework:" \
                "Rails" "Sinatra" "None"
            case "$MENU_INDEX" in
                1) FRAMEWORK="rails" ;;
                2) FRAMEWORK="sinatra" ;;
                3) FRAMEWORK="" ;;
            esac
            ;;
        java)
            numbered_menu "Select framework:" \
                "Spring Boot" "None"
            case "$MENU_INDEX" in
                1) FRAMEWORK="spring" ;;
                2) FRAMEWORK="" ;;
            esac
            ;;
        rust)
            numbered_menu "Select framework:" \
                "Actix Web" "Axum" "Rocket" "None (CLI/lib)"
            case "$MENU_INDEX" in
                1) FRAMEWORK="actix" ;;
                2) FRAMEWORK="axum" ;;
                3) FRAMEWORK="rocket" ;;
                4) FRAMEWORK="" ;;
            esac
            ;;
        *)
            FRAMEWORK=""
            ;;
    esac
}

prompt_pkg_manager() {
    case "$LANGUAGE" in
        typescript|javascript)
            numbered_menu "Select package manager:" \
                "npm" "yarn" "pnpm" "bun"
            case "$MENU_INDEX" in
                1) PKG_MANAGER="npm" ;;
                2) PKG_MANAGER="yarn" ;;
                3) PKG_MANAGER="pnpm" ;;
                4) PKG_MANAGER="bun" ;;
            esac
            ;;
        python)
            numbered_menu "Select package manager:" \
                "pip" "uv" "poetry" "pipenv"
            case "$MENU_INDEX" in
                1) PKG_MANAGER="pip" ;;
                2) PKG_MANAGER="uv" ;;
                3) PKG_MANAGER="poetry" ;;
                4) PKG_MANAGER="pipenv" ;;
            esac
            ;;
        *)
            # Use detected or sensible default
            if [ -z "$PKG_MANAGER" ]; then
                PKG_MANAGER="$DETECTED_PKG_MANAGER"
            fi
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Phase 3: Development Conventions
# ---------------------------------------------------------------------------
phase_conventions() {
    header "Phase 3: Development Conventions"

    # Test framework
    if [ -z "$TEST_FRAMEWORK" ]; then
        TEST_FRAMEWORK="$DETECTED_TEST_FRAMEWORK"
    fi
    if [ -n "$TEST_FRAMEWORK" ]; then
        info "Detected test framework: $TEST_FRAMEWORK"
        if ! confirm "Use $TEST_FRAMEWORK?"; then
            prompt_test_framework
        fi
    else
        prompt_test_framework
    fi

    # Linter
    if [ -z "$LINTER" ]; then
        LINTER="$DETECTED_LINTER"
    fi
    if [ -n "$LINTER" ]; then
        info "Detected linter: $LINTER"
        if ! confirm "Use $LINTER?"; then
            LINTER=""
        fi
    fi

    # Formatter
    if [ -z "$FORMATTER" ]; then
        FORMATTER="$DETECTED_FORMATTER"
    fi
    if [ -n "$FORMATTER" ]; then
        info "Detected formatter: $FORMATTER"
        if ! confirm "Use $FORMATTER?"; then
            FORMATTER=""
        fi
    fi

    # TDD preference
    numbered_menu "TDD preference:" \
        "Yes - write tests first" \
        "Tests alongside - write tests with implementation" \
        "Tests after - write tests after implementation" \
        "No preference"
    case "$MENU_INDEX" in
        1) TDD_PREFERENCE="strict" ;;
        2) TDD_PREFERENCE="alongside" ;;
        3) TDD_PREFERENCE="after" ;;
        4) TDD_PREFERENCE="none" ;;
    esac

    # Naming convention
    case "$LANGUAGE" in
        typescript|javascript)
            NAMING_CONVENTION="camelCase for variables/functions, PascalCase for classes/components, UPPER_SNAKE for constants"
            ;;
        python)
            NAMING_CONVENTION="snake_case for functions/variables, PascalCase for classes, UPPER_SNAKE for constants"
            ;;
        go)
            NAMING_CONVENTION="camelCase for unexported, PascalCase for exported, short names preferred"
            ;;
        rust)
            NAMING_CONVENTION="snake_case for functions/variables, PascalCase for types/traits, UPPER_SNAKE for constants"
            ;;
        ruby)
            NAMING_CONVENTION="snake_case for methods/variables, PascalCase for classes/modules, UPPER_SNAKE for constants"
            ;;
        java)
            NAMING_CONVENTION="camelCase for methods/variables, PascalCase for classes, UPPER_SNAKE for constants"
            ;;
        *)
            NAMING_CONVENTION=""
            ;;
    esac

    if [ -n "$NAMING_CONVENTION" ]; then
        info "Naming: $NAMING_CONVENTION"
    fi

    # Commands
    _prompt_commands
}

prompt_test_framework() {
    case "$LANGUAGE" in
        typescript|javascript)
            numbered_menu "Select test framework:" \
                "Vitest" "Jest" "Playwright" "Mocha" "None"
            case "$MENU_INDEX" in
                1) TEST_FRAMEWORK="vitest" ;;
                2) TEST_FRAMEWORK="jest" ;;
                3) TEST_FRAMEWORK="playwright" ;;
                4) TEST_FRAMEWORK="mocha" ;;
                5) TEST_FRAMEWORK="" ;;
            esac
            ;;
        python)
            numbered_menu "Select test framework:" \
                "pytest" "unittest" "None"
            case "$MENU_INDEX" in
                1) TEST_FRAMEWORK="pytest" ;;
                2) TEST_FRAMEWORK="unittest" ;;
                3) TEST_FRAMEWORK="" ;;
            esac
            ;;
        *)
            TEST_FRAMEWORK="$DETECTED_TEST_FRAMEWORK"
            ;;
    esac
}

_prompt_commands() {
    printf "\n"
    info "Common commands (press Enter to accept detected, or type to override)"

    CMD_BUILD="$(read_input "  Build command" "${DETECTED_CMD_BUILD}")"
    printf '\n'
    CMD_DEV="$(read_input "  Dev/run command" "${DETECTED_CMD_DEV}")"
    printf '\n'
    CMD_TEST="$(read_input "  Test command" "${DETECTED_CMD_TEST}")"
    printf '\n'
    CMD_LINT="$(read_input "  Lint command" "${DETECTED_CMD_LINT}")"
    printf '\n'
    CMD_FORMAT="$(read_input "  Format command" "${DETECTED_CMD_FORMAT}")"
    printf '\n'
}

# ---------------------------------------------------------------------------
# Phase 4: Git Workflow & Claude Features
# ---------------------------------------------------------------------------
phase_git_and_skills() {
    header "Phase 4: Git Workflow & Skills"

    # Commit style
    numbered_menu "Commit message style:" \
        "Conventional Commits (feat:, fix:, etc.)" \
        "Descriptive (plain English)" \
        "Ticket-prefixed (PROJ-123: description)" \
        "No preference"
    case "$MENU_INDEX" in
        1) COMMIT_STYLE="conventional" ;;
        2) COMMIT_STYLE="descriptive" ;;
        3) COMMIT_STYLE="ticket" ;;
        4) COMMIT_STYLE="none" ;;
    esac

    # Branching strategy
    numbered_menu "Branching strategy:" \
        "GitHub Flow (feature branches + PRs)" \
        "Git Flow (develop/release/hotfix)" \
        "Trunk-based (short-lived branches)" \
        "No preference"
    case "$MENU_INDEX" in
        1) BRANCH_STRATEGY="github-flow" ;;
        2) BRANCH_STRATEGY="git-flow" ;;
        3) BRANCH_STRATEGY="trunk" ;;
        4) BRANCH_STRATEGY="none" ;;
    esac

    # Skills selection
    multi_select "Select skills to generate:" \
        "/review - Code review" \
        "/test - Run and analyze tests" \
        "/fix-issue - Fix GitHub issue" \
        "/deploy - Pre-deploy checklist" \
        "/tdd - Red-green-refactor" \
        "/document - Generate docs"

    SELECTED_SKILLS="$MULTI_CHOICES"

    # Add context-specific skills
    case "$LANGUAGE" in
        typescript|javascript)
            if [ -n "$FRAMEWORK" ]; then
                case "$FRAMEWORK" in
                    nextjs|react|vue|svelte|angular)
                        multi_select "Additional web skills:" \
                            "/component - Create component" \
                            "/page - Create page/route"
                        if [ -n "$MULTI_CHOICES" ]; then
                            SELECTED_SKILLS="$SELECTED_SKILLS|$MULTI_CHOICES"
                        fi
                        ;;
                    express|fastify|hono)
                        multi_select "Additional API skills:" \
                            "/endpoint - Create API endpoint" \
                            "/middleware - Create middleware"
                        if [ -n "$MULTI_CHOICES" ]; then
                            SELECTED_SKILLS="$SELECTED_SKILLS|$MULTI_CHOICES"
                        fi
                        ;;
                esac
            fi
            ;;
        python)
            case "$FRAMEWORK" in
                fastapi|flask|django)
                    multi_select "Additional API skills:" \
                        "/endpoint - Create API endpoint" \
                        "/model - Create data model"
                    if [ -n "$MULTI_CHOICES" ]; then
                        SELECTED_SKILLS="$SELECTED_SKILLS|$MULTI_CHOICES"
                    fi
                    ;;
            esac
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Run all prompt phases
# ---------------------------------------------------------------------------
run_prompts() {
    phase_safety_checks || return 1
    phase_project_basics
    phase_conventions
    phase_git_and_skills
    return 0
}
