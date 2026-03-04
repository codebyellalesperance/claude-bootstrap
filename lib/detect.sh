#!/bin/sh
# detect.sh - Auto-detect language, framework, package manager, tooling
# POSIX-compliant, zero dependencies

# ---------------------------------------------------------------------------
# Main detection entry point
# ---------------------------------------------------------------------------
run_detection() {
    DETECTED_LANGUAGE=""
    DETECTED_FRAMEWORK=""
    DETECTED_PKG_MANAGER=""
    DETECTED_TEST_FRAMEWORK=""
    DETECTED_LINTER=""
    DETECTED_FORMATTER=""
    DETECTED_PROJECT_NAME=""
    DETECTED_DESCRIPTION=""
    DETECTED_CMD_BUILD=""
    DETECTED_CMD_DEV=""
    DETECTED_CMD_TEST=""
    DETECTED_CMD_LINT=""
    DETECTED_CMD_FORMAT=""
    DETECTED_HAS_DOCKER=0
    DETECTED_HAS_CI=0

    detect_language
    detect_framework
    detect_pkg_manager
    detect_test_framework
    detect_linter
    detect_formatter
    detect_commands
    detect_project_meta
    detect_extras
}

# ---------------------------------------------------------------------------
# Language detection
# ---------------------------------------------------------------------------
detect_language() {
    if [ -f "tsconfig.json" ] || [ -f "tsconfig.base.json" ]; then
        DETECTED_LANGUAGE="typescript"
    elif [ -f "package.json" ]; then
        DETECTED_LANGUAGE="javascript"
        # Check if package.json references typescript
        if [ -f "package.json" ]; then
            if grep -q '"typescript"' package.json 2>/dev/null; then
                DETECTED_LANGUAGE="typescript"
            fi
        fi
    elif [ -f "pyproject.toml" ] || [ -f "setup.py" ] || [ -f "setup.cfg" ] || [ -f "requirements.txt" ] || [ -f "Pipfile" ]; then
        DETECTED_LANGUAGE="python"
    elif [ -f "go.mod" ]; then
        DETECTED_LANGUAGE="go"
    elif [ -f "Cargo.toml" ]; then
        DETECTED_LANGUAGE="rust"
    elif [ -f "pom.xml" ] || [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
        DETECTED_LANGUAGE="java"
    elif [ -f "Gemfile" ]; then
        DETECTED_LANGUAGE="ruby"
    elif [ -f "*.csproj" ] 2>/dev/null || [ -f "*.sln" ] 2>/dev/null || [ -d "obj" ]; then
        DETECTED_LANGUAGE="csharp"
        # More reliable C# detection
    fi

    # Fallback: check for csproj/sln files more carefully
    if [ -z "$DETECTED_LANGUAGE" ]; then
        for f in *.csproj *.sln; do
            if [ -f "$f" ]; then
                DETECTED_LANGUAGE="csharp"
                break
            fi
        done
    fi
}

# ---------------------------------------------------------------------------
# Framework detection
# ---------------------------------------------------------------------------
detect_framework() {
    case "$DETECTED_LANGUAGE" in
        typescript|javascript)
            detect_js_framework
            ;;
        python)
            detect_python_framework
            ;;
        go)
            detect_go_framework
            ;;
        ruby)
            detect_ruby_framework
            ;;
        java)
            detect_java_framework
            ;;
        rust)
            detect_rust_framework
            ;;
    esac
}

detect_js_framework() {
    if [ ! -f "package.json" ]; then return; fi

    if grep -q '"next"' package.json 2>/dev/null; then
        DETECTED_FRAMEWORK="nextjs"
    elif grep -q '"nuxt"' package.json 2>/dev/null; then
        DETECTED_FRAMEWORK="nuxt"
    elif grep -q '"svelte"' package.json 2>/dev/null || [ -f "svelte.config.js" ]; then
        DETECTED_FRAMEWORK="svelte"
    elif grep -q '"vue"' package.json 2>/dev/null || [ -f "vue.config.js" ]; then
        DETECTED_FRAMEWORK="vue"
    elif grep -q '"@angular/core"' package.json 2>/dev/null || [ -f "angular.json" ]; then
        DETECTED_FRAMEWORK="angular"
    elif grep -q '"express"' package.json 2>/dev/null; then
        DETECTED_FRAMEWORK="express"
    elif grep -q '"fastify"' package.json 2>/dev/null; then
        DETECTED_FRAMEWORK="fastify"
    elif grep -q '"hono"' package.json 2>/dev/null; then
        DETECTED_FRAMEWORK="hono"
    elif grep -q '"react"' package.json 2>/dev/null; then
        DETECTED_FRAMEWORK="react"
    fi
}

detect_python_framework() {
    # Check pyproject.toml first, then requirements
    _check_python_dep() {
        _dep="$1"
        if [ -f "pyproject.toml" ] && grep -qi "$_dep" pyproject.toml 2>/dev/null; then
            return 0
        fi
        if [ -f "requirements.txt" ] && grep -qi "$_dep" requirements.txt 2>/dev/null; then
            return 0
        fi
        if [ -f "Pipfile" ] && grep -qi "$_dep" Pipfile 2>/dev/null; then
            return 0
        fi
        if [ -f "setup.py" ] && grep -qi "$_dep" setup.py 2>/dev/null; then
            return 0
        fi
        return 1
    }

    if _check_python_dep "fastapi"; then
        DETECTED_FRAMEWORK="fastapi"
    elif _check_python_dep "django"; then
        DETECTED_FRAMEWORK="django"
    elif _check_python_dep "flask"; then
        DETECTED_FRAMEWORK="flask"
    elif _check_python_dep "starlette"; then
        DETECTED_FRAMEWORK="starlette"
    fi
}

detect_go_framework() {
    if [ ! -f "go.mod" ]; then return; fi

    if grep -q "gin-gonic/gin" go.mod 2>/dev/null; then
        DETECTED_FRAMEWORK="gin"
    elif grep -q "labstack/echo" go.mod 2>/dev/null; then
        DETECTED_FRAMEWORK="echo"
    elif grep -q "go-chi/chi" go.mod 2>/dev/null; then
        DETECTED_FRAMEWORK="chi"
    elif grep -q "gofiber/fiber" go.mod 2>/dev/null; then
        DETECTED_FRAMEWORK="fiber"
    fi
}

detect_ruby_framework() {
    if [ -f "Gemfile" ] && grep -q "rails" Gemfile 2>/dev/null; then
        DETECTED_FRAMEWORK="rails"
    elif [ -f "Gemfile" ] && grep -q "sinatra" Gemfile 2>/dev/null; then
        DETECTED_FRAMEWORK="sinatra"
    fi
}

detect_java_framework() {
    if [ -f "pom.xml" ] && grep -q "spring-boot" pom.xml 2>/dev/null; then
        DETECTED_FRAMEWORK="spring"
    elif [ -f "build.gradle" ] && grep -q "spring-boot" build.gradle 2>/dev/null; then
        DETECTED_FRAMEWORK="spring"
    elif [ -f "build.gradle.kts" ] && grep -q "spring-boot" build.gradle.kts 2>/dev/null; then
        DETECTED_FRAMEWORK="spring"
    fi
}

detect_rust_framework() {
    if [ ! -f "Cargo.toml" ]; then return; fi

    if grep -q "actix-web" Cargo.toml 2>/dev/null; then
        DETECTED_FRAMEWORK="actix"
    elif grep -q "axum" Cargo.toml 2>/dev/null; then
        DETECTED_FRAMEWORK="axum"
    elif grep -q "rocket" Cargo.toml 2>/dev/null; then
        DETECTED_FRAMEWORK="rocket"
    fi
}

# ---------------------------------------------------------------------------
# Package manager detection
# ---------------------------------------------------------------------------
detect_pkg_manager() {
    case "$DETECTED_LANGUAGE" in
        typescript|javascript)
            if [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
                DETECTED_PKG_MANAGER="bun"
            elif [ -f "pnpm-lock.yaml" ]; then
                DETECTED_PKG_MANAGER="pnpm"
            elif [ -f "yarn.lock" ]; then
                DETECTED_PKG_MANAGER="yarn"
            elif [ -f "package-lock.json" ]; then
                DETECTED_PKG_MANAGER="npm"
            else
                DETECTED_PKG_MANAGER="npm"
            fi
            ;;
        python)
            if [ -f "uv.lock" ] || ([ -f "pyproject.toml" ] && grep -q '\[tool\.uv\]' pyproject.toml 2>/dev/null); then
                DETECTED_PKG_MANAGER="uv"
            elif [ -f "poetry.lock" ]; then
                DETECTED_PKG_MANAGER="poetry"
            elif [ -f "Pipfile.lock" ] || [ -f "Pipfile" ]; then
                DETECTED_PKG_MANAGER="pipenv"
            elif [ -f "conda.yaml" ] || [ -f "environment.yml" ]; then
                DETECTED_PKG_MANAGER="conda"
            else
                DETECTED_PKG_MANAGER="pip"
            fi
            ;;
        go)
            DETECTED_PKG_MANAGER="go"
            ;;
        rust)
            DETECTED_PKG_MANAGER="cargo"
            ;;
        java)
            if [ -f "pom.xml" ]; then
                DETECTED_PKG_MANAGER="maven"
            elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
                DETECTED_PKG_MANAGER="gradle"
            fi
            ;;
        ruby)
            DETECTED_PKG_MANAGER="bundler"
            ;;
        csharp)
            DETECTED_PKG_MANAGER="dotnet"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Test framework detection
# ---------------------------------------------------------------------------
detect_test_framework() {
    case "$DETECTED_LANGUAGE" in
        typescript|javascript)
            if [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ] || \
               ([ -f "package.json" ] && grep -q '"vitest"' package.json 2>/dev/null); then
                DETECTED_TEST_FRAMEWORK="vitest"
            elif [ -f "jest.config.ts" ] || [ -f "jest.config.js" ] || [ -f "jest.config.cjs" ] || \
                 ([ -f "package.json" ] && grep -q '"jest"' package.json 2>/dev/null); then
                DETECTED_TEST_FRAMEWORK="jest"
            elif [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ]; then
                DETECTED_TEST_FRAMEWORK="playwright"
            elif [ -f ".mocharc.yml" ] || [ -f ".mocharc.json" ]; then
                DETECTED_TEST_FRAMEWORK="mocha"
            fi
            ;;
        python)
            if [ -f "pyproject.toml" ] && grep -q "pytest" pyproject.toml 2>/dev/null; then
                DETECTED_TEST_FRAMEWORK="pytest"
            elif [ -f "pytest.ini" ] || [ -f "conftest.py" ] || [ -d "tests" ]; then
                DETECTED_TEST_FRAMEWORK="pytest"
            elif [ -f "requirements.txt" ] && grep -q "pytest" requirements.txt 2>/dev/null; then
                DETECTED_TEST_FRAMEWORK="pytest"
            else
                DETECTED_TEST_FRAMEWORK="unittest"
            fi
            ;;
        go)
            DETECTED_TEST_FRAMEWORK="go test"
            ;;
        rust)
            DETECTED_TEST_FRAMEWORK="cargo test"
            ;;
        java)
            DETECTED_TEST_FRAMEWORK="junit"
            ;;
        ruby)
            if [ -f "Gemfile" ] && grep -q "rspec" Gemfile 2>/dev/null; then
                DETECTED_TEST_FRAMEWORK="rspec"
            else
                DETECTED_TEST_FRAMEWORK="minitest"
            fi
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Linter detection
# ---------------------------------------------------------------------------
detect_linter() {
    case "$DETECTED_LANGUAGE" in
        typescript|javascript)
            if [ -f "biome.json" ] || [ -f "biome.jsonc" ]; then
                DETECTED_LINTER="biome"
            elif [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f ".eslintrc.yml" ] || \
                 [ -f ".eslintrc.cjs" ] || [ -f "eslint.config.js" ] || [ -f "eslint.config.mjs" ] || \
                 [ -f "eslint.config.ts" ]; then
                DETECTED_LINTER="eslint"
            elif [ -f "package.json" ] && grep -q '"eslint"' package.json 2>/dev/null; then
                DETECTED_LINTER="eslint"
            fi
            ;;
        python)
            if [ -f "pyproject.toml" ] && grep -q '\[tool\.ruff\]' pyproject.toml 2>/dev/null; then
                DETECTED_LINTER="ruff"
            elif [ -f "ruff.toml" ]; then
                DETECTED_LINTER="ruff"
            elif [ -f ".flake8" ] || [ -f "setup.cfg" ] && grep -q "flake8" setup.cfg 2>/dev/null; then
                DETECTED_LINTER="flake8"
            elif [ -f ".pylintrc" ] || [ -f "pyproject.toml" ] && grep -q "pylint" pyproject.toml 2>/dev/null; then
                DETECTED_LINTER="pylint"
            fi
            ;;
        go)
            if [ -f ".golangci.yml" ] || [ -f ".golangci.yaml" ] || [ -f ".golangci.json" ]; then
                DETECTED_LINTER="golangci-lint"
            fi
            ;;
        rust)
            DETECTED_LINTER="clippy"
            ;;
        ruby)
            if [ -f ".rubocop.yml" ]; then
                DETECTED_LINTER="rubocop"
            fi
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Formatter detection
# ---------------------------------------------------------------------------
detect_formatter() {
    case "$DETECTED_LANGUAGE" in
        typescript|javascript)
            if [ -f "biome.json" ] || [ -f "biome.jsonc" ]; then
                DETECTED_FORMATTER="biome"
            elif [ -f ".prettierrc" ] || [ -f ".prettierrc.js" ] || [ -f ".prettierrc.json" ] || \
                 [ -f ".prettierrc.yml" ] || [ -f "prettier.config.js" ] || [ -f "prettier.config.mjs" ]; then
                DETECTED_FORMATTER="prettier"
            elif [ -f "package.json" ] && grep -q '"prettier"' package.json 2>/dev/null; then
                DETECTED_FORMATTER="prettier"
            fi
            ;;
        python)
            if [ -f "pyproject.toml" ] && grep -q '\[tool\.ruff' pyproject.toml 2>/dev/null; then
                DETECTED_FORMATTER="ruff"
            elif [ -f "pyproject.toml" ] && grep -q '\[tool\.black\]' pyproject.toml 2>/dev/null; then
                DETECTED_FORMATTER="black"
            elif [ -f ".black.cfg" ]; then
                DETECTED_FORMATTER="black"
            fi
            ;;
        go)
            DETECTED_FORMATTER="gofmt"
            ;;
        rust)
            DETECTED_FORMATTER="rustfmt"
            ;;
        ruby)
            if [ -f ".rubocop.yml" ]; then
                DETECTED_FORMATTER="rubocop"
            fi
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Command detection
# ---------------------------------------------------------------------------
detect_commands() {
    _run=""
    case "$DETECTED_PKG_MANAGER" in
        npm)   _run="npm run" ;;
        yarn)  _run="yarn" ;;
        pnpm)  _run="pnpm" ;;
        bun)   _run="bun run" ;;
    esac

    case "$DETECTED_LANGUAGE" in
        typescript|javascript)
            if [ -f "package.json" ]; then
                if grep -q '"build"' package.json 2>/dev/null; then
                    DETECTED_CMD_BUILD="$_run build"
                fi
                if grep -q '"dev"' package.json 2>/dev/null; then
                    DETECTED_CMD_DEV="$_run dev"
                elif grep -q '"start"' package.json 2>/dev/null; then
                    DETECTED_CMD_DEV="$_run start"
                fi
                if grep -q '"test"' package.json 2>/dev/null; then
                    DETECTED_CMD_TEST="$_run test"
                fi
                if grep -q '"lint"' package.json 2>/dev/null; then
                    DETECTED_CMD_LINT="$_run lint"
                fi
                if grep -q '"format"' package.json 2>/dev/null; then
                    DETECTED_CMD_FORMAT="$_run format"
                fi
            fi
            ;;
        python)
            case "$DETECTED_PKG_MANAGER" in
                uv)
                    DETECTED_CMD_TEST="uv run pytest"
                    if [ -n "$DETECTED_LINTER" ]; then
                        DETECTED_CMD_LINT="uv run $DETECTED_LINTER check ."
                    fi
                    if [ -n "$DETECTED_FORMATTER" ]; then
                        DETECTED_CMD_FORMAT="uv run $DETECTED_FORMATTER format ."
                    fi
                    ;;
                poetry)
                    DETECTED_CMD_TEST="poetry run pytest"
                    if [ -n "$DETECTED_LINTER" ]; then
                        DETECTED_CMD_LINT="poetry run $DETECTED_LINTER check ."
                    fi
                    if [ -n "$DETECTED_FORMATTER" ]; then
                        DETECTED_CMD_FORMAT="poetry run $DETECTED_FORMATTER format ."
                    fi
                    ;;
                *)
                    DETECTED_CMD_TEST="pytest"
                    if [ -n "$DETECTED_LINTER" ]; then
                        DETECTED_CMD_LINT="$DETECTED_LINTER check ."
                    fi
                    if [ -n "$DETECTED_FORMATTER" ]; then
                        DETECTED_CMD_FORMAT="$DETECTED_FORMATTER format ."
                    fi
                    ;;
            esac
            case "$DETECTED_FRAMEWORK" in
                fastapi)
                    DETECTED_CMD_DEV="uvicorn main:app --reload"
                    ;;
                django)
                    DETECTED_CMD_DEV="python manage.py runserver"
                    DETECTED_CMD_TEST="${DETECTED_CMD_TEST:-python manage.py test}"
                    ;;
                flask)
                    DETECTED_CMD_DEV="flask run --debug"
                    ;;
            esac
            ;;
        go)
            DETECTED_CMD_BUILD="go build ./..."
            DETECTED_CMD_TEST="go test ./..."
            if [ "$DETECTED_LINTER" = "golangci-lint" ]; then
                DETECTED_CMD_LINT="golangci-lint run"
            else
                DETECTED_CMD_LINT="go vet ./..."
            fi
            DETECTED_CMD_FORMAT="gofmt -w ."
            ;;
        rust)
            DETECTED_CMD_BUILD="cargo build"
            DETECTED_CMD_TEST="cargo test"
            DETECTED_CMD_LINT="cargo clippy"
            DETECTED_CMD_FORMAT="cargo fmt"
            ;;
        java)
            case "$DETECTED_PKG_MANAGER" in
                maven)
                    DETECTED_CMD_BUILD="mvn compile"
                    DETECTED_CMD_TEST="mvn test"
                    ;;
                gradle)
                    DETECTED_CMD_BUILD="./gradlew build"
                    DETECTED_CMD_TEST="./gradlew test"
                    ;;
            esac
            ;;
        ruby)
            if [ "$DETECTED_FRAMEWORK" = "rails" ]; then
                DETECTED_CMD_DEV="rails server"
                DETECTED_CMD_TEST="rails test"
            elif [ "$DETECTED_TEST_FRAMEWORK" = "rspec" ]; then
                DETECTED_CMD_TEST="bundle exec rspec"
            fi
            if [ "$DETECTED_LINTER" = "rubocop" ]; then
                DETECTED_CMD_LINT="bundle exec rubocop"
                DETECTED_CMD_FORMAT="bundle exec rubocop -A"
            fi
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Project meta detection
# ---------------------------------------------------------------------------
detect_project_meta() {
    # Try package.json first
    if [ -f "package.json" ]; then
        DETECTED_PROJECT_NAME="$(grep '"name"' package.json 2>/dev/null | head -1 | sed 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
        DETECTED_DESCRIPTION="$(grep '"description"' package.json 2>/dev/null | head -1 | sed 's/.*"description"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"
    fi

    # Try pyproject.toml
    if [ -z "$DETECTED_PROJECT_NAME" ] && [ -f "pyproject.toml" ]; then
        DETECTED_PROJECT_NAME="$(grep '^name' pyproject.toml 2>/dev/null | head -1 | sed 's/.*=[[:space:]]*"\([^"]*\)".*/\1/')"
        DETECTED_DESCRIPTION="$(grep '^description' pyproject.toml 2>/dev/null | head -1 | sed 's/.*=[[:space:]]*"\([^"]*\)".*/\1/')"
    fi

    # Try Cargo.toml
    if [ -z "$DETECTED_PROJECT_NAME" ] && [ -f "Cargo.toml" ]; then
        DETECTED_PROJECT_NAME="$(grep '^name' Cargo.toml 2>/dev/null | head -1 | sed 's/.*=[[:space:]]*"\([^"]*\)".*/\1/')"
        DETECTED_DESCRIPTION="$(grep '^description' Cargo.toml 2>/dev/null | head -1 | sed 's/.*=[[:space:]]*"\([^"]*\)".*/\1/')"
    fi

    # Try go.mod
    if [ -z "$DETECTED_PROJECT_NAME" ] && [ -f "go.mod" ]; then
        DETECTED_PROJECT_NAME="$(grep '^module' go.mod 2>/dev/null | head -1 | awk '{print $2}' | sed 's|.*/||')"
    fi

    # Fallback to directory name
    if [ -z "$DETECTED_PROJECT_NAME" ]; then
        DETECTED_PROJECT_NAME="$(basename "$(pwd)")"
    fi
}

# ---------------------------------------------------------------------------
# Extra detection (Docker, CI, etc.)
# ---------------------------------------------------------------------------
detect_extras() {
    if [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] || [ -f "docker-compose.yaml" ] || [ -f "compose.yml" ]; then
        DETECTED_HAS_DOCKER=1
    fi

    if [ -d ".github/workflows" ] || [ -f ".gitlab-ci.yml" ] || [ -f ".circleci/config.yml" ]; then
        DETECTED_HAS_CI=1
    fi
}

# ---------------------------------------------------------------------------
# Safety check: are we in a project directory?
# ---------------------------------------------------------------------------
check_project_dir() {
    _cwd="$(pwd)"

    # Never run in HOME or root
    if [ "$_cwd" = "$HOME" ] || [ "$_cwd" = "/" ]; then
        error "Refusing to run in $HOME or /. Please cd into a project directory."
        return 1
    fi

    # Check for project indicators
    _has_indicator=0
    for _f in .git package.json pyproject.toml go.mod Cargo.toml Gemfile pom.xml build.gradle Makefile README.md; do
        if [ -e "$_f" ]; then
            _has_indicator=1
            break
        fi
    done

    if [ "$_has_indicator" -eq 0 ]; then
        warn "No project indicators found (no .git, package.json, etc.)"
        if ! confirm "Continue anyway?"; then
            return 1
        fi
    fi

    return 0
}

# ---------------------------------------------------------------------------
# Display detected stack
# ---------------------------------------------------------------------------
show_detection() {
    header "Detected Stack"
    if [ -n "$DETECTED_LANGUAGE" ]; then
        printf "  Language:      ${GREEN}%s${RESET}\n" "$DETECTED_LANGUAGE"
    else
        printf "  Language:      ${DIM}(not detected)${RESET}\n"
    fi
    if [ -n "$DETECTED_FRAMEWORK" ]; then
        printf "  Framework:     ${GREEN}%s${RESET}\n" "$DETECTED_FRAMEWORK"
    fi
    if [ -n "$DETECTED_PKG_MANAGER" ]; then
        printf "  Pkg Manager:   ${GREEN}%s${RESET}\n" "$DETECTED_PKG_MANAGER"
    fi
    if [ -n "$DETECTED_TEST_FRAMEWORK" ]; then
        printf "  Test:          ${GREEN}%s${RESET}\n" "$DETECTED_TEST_FRAMEWORK"
    fi
    if [ -n "$DETECTED_LINTER" ]; then
        printf "  Linter:        ${GREEN}%s${RESET}\n" "$DETECTED_LINTER"
    fi
    if [ -n "$DETECTED_FORMATTER" ]; then
        printf "  Formatter:     ${GREEN}%s${RESET}\n" "$DETECTED_FORMATTER"
    fi
    printf "\n"
}
