#!/bin/sh
# generate.sh - Compose templates into final output files
# POSIX-compliant, zero dependencies

# ---------------------------------------------------------------------------
# Main CLAUDE.md generator
# ---------------------------------------------------------------------------
generate_claude_md() {
    section_project_overview
    section_tech_stack
    section_commands
    section_conventions
    section_testing
    section_git_workflow
    section_gotchas
}

# ---------------------------------------------------------------------------
# Section: Project Overview
# ---------------------------------------------------------------------------
section_project_overview() {
    printf '# %s\n\n' "$PROJECT_NAME"
    if [ -n "$DESCRIPTION" ]; then
        printf '%s\n\n' "$DESCRIPTION"
    fi
}

# ---------------------------------------------------------------------------
# Section: Tech Stack
# ---------------------------------------------------------------------------
section_tech_stack() {
    printf '## Tech Stack\n\n'

    if [ -n "$LANGUAGE" ]; then
        _lang_display="$(echo "$LANGUAGE" | sed 's/typescript/TypeScript/;s/javascript/JavaScript/;s/python/Python/;s/go/Go/;s/rust/Rust/;s/java/Java/;s/ruby/Ruby/;s/csharp/C#/')"
        printf -- '- **Language**: %s\n' "$_lang_display"
    fi
    if [ -n "$FRAMEWORK" ]; then
        _fw_display="$(format_framework_name "$FRAMEWORK")"
        printf -- '- **Framework**: %s\n' "$_fw_display"
    fi
    if [ -n "$PKG_MANAGER" ]; then
        printf -- '- **Package Manager**: %s\n' "$PKG_MANAGER"
    fi
    if [ -n "$TEST_FRAMEWORK" ]; then
        printf -- '- **Testing**: %s\n' "$TEST_FRAMEWORK"
    fi
    if [ -n "$LINTER" ]; then
        printf -- '- **Linter**: %s\n' "$LINTER"
    fi
    if [ -n "$FORMATTER" ]; then
        printf -- '- **Formatter**: %s\n' "$FORMATTER"
    fi
    printf '\n'
}

format_framework_name() {
    case "$1" in
        nextjs)   printf 'Next.js' ;;
        react)    printf 'React' ;;
        vue)      printf 'Vue' ;;
        svelte)   printf 'Svelte' ;;
        angular)  printf 'Angular' ;;
        express)  printf 'Express' ;;
        fastify)  printf 'Fastify' ;;
        hono)     printf 'Hono' ;;
        fastapi)  printf 'FastAPI' ;;
        django)   printf 'Django' ;;
        flask)    printf 'Flask' ;;
        gin)      printf 'Gin' ;;
        echo)     printf 'Echo' ;;
        chi)      printf 'Chi' ;;
        fiber)    printf 'Fiber' ;;
        rails)    printf 'Rails' ;;
        sinatra)  printf 'Sinatra' ;;
        spring)   printf 'Spring Boot' ;;
        actix)    printf 'Actix Web' ;;
        axum)     printf 'Axum' ;;
        rocket)   printf 'Rocket' ;;
        *)        printf '%s' "$1" ;;
    esac
}

# ---------------------------------------------------------------------------
# Section: Commands
# ---------------------------------------------------------------------------
section_commands() {
    _has_cmd=0
    for _c in "$CMD_BUILD" "$CMD_DEV" "$CMD_TEST" "$CMD_LINT" "$CMD_FORMAT"; do
        if [ -n "$_c" ]; then _has_cmd=1; break; fi
    done

    if [ "$_has_cmd" -eq 0 ]; then return; fi

    printf '## Common Commands\n\n'
    printf '```sh\n'
    if [ -n "$CMD_BUILD" ];  then printf '# Build\n%s\n\n' "$CMD_BUILD"; fi
    if [ -n "$CMD_DEV" ];    then printf '# Dev server\n%s\n\n' "$CMD_DEV"; fi
    if [ -n "$CMD_TEST" ];   then printf '# Run tests\n%s\n\n' "$CMD_TEST"; fi
    if [ -n "$CMD_LINT" ];   then printf '# Lint\n%s\n\n' "$CMD_LINT"; fi
    if [ -n "$CMD_FORMAT" ]; then printf '# Format\n%s\n' "$CMD_FORMAT"; fi
    printf '```\n\n'
}

# ---------------------------------------------------------------------------
# Section: Conventions
# ---------------------------------------------------------------------------
section_conventions() {
    printf '## Coding Conventions\n\n'

    # Naming
    if [ -n "$NAMING_CONVENTION" ]; then
        printf -- '- **Naming**: %s\n' "$NAMING_CONVENTION"
    fi

    # Language-specific conventions
    _lang_conventions

    # Framework-specific conventions
    _framework_conventions

    printf '\n'
}

_lang_conventions() {
    case "$LANGUAGE" in
        typescript)
            printf -- '- Use TypeScript strict mode; avoid `any` types\n'
            printf -- '- Prefer `interface` over `type` for object shapes\n'
            printf -- '- Use explicit return types on exported functions\n'
            ;;
        javascript)
            printf -- '- Use modern ES6+ syntax (const/let, arrow functions, destructuring)\n'
            printf -- '- Prefer named exports over default exports\n'
            ;;
        python)
            printf -- '- Follow PEP 8 style guide\n'
            printf -- '- Use type hints for function signatures\n'
            printf -- '- Prefer f-strings for string formatting\n'
            ;;
        go)
            printf -- '- Follow Effective Go guidelines\n'
            printf -- '- Handle errors explicitly; do not ignore error returns\n'
            printf -- '- Keep functions short and focused\n'
            ;;
        rust)
            printf -- '- Follow Rust API Guidelines\n'
            printf -- '- Prefer `Result` over `panic!` for error handling\n'
            printf -- '- Use `clippy` warnings as guidance\n'
            ;;
        java)
            printf -- '- Follow standard Java conventions\n'
            printf -- '- Use meaningful names; avoid abbreviations\n'
            ;;
        ruby)
            printf -- '- Follow Ruby Style Guide\n'
            printf -- '- Prefer single-line blocks for short operations\n'
            ;;
    esac
}

_framework_conventions() {
    case "$FRAMEWORK" in
        nextjs)
            printf -- '- Use App Router (app/) unless the project uses Pages Router\n'
            printf -- '- Prefer Server Components by default; use "use client" only when needed\n'
            printf -- '- Co-locate components, tests, and styles near their routes\n'
            ;;
        react)
            printf -- '- Use functional components with hooks\n'
            printf -- '- Keep components small and focused\n'
            printf -- '- Lift state up only when necessary\n'
            ;;
        vue)
            printf -- '- Use Composition API with `<script setup>`\n'
            printf -- '- Follow Vue style guide priority rules\n'
            ;;
        svelte)
            printf -- '- Use Svelte 5 runes syntax where applicable\n'
            printf -- '- Keep components small and composable\n'
            ;;
        express|fastify|hono)
            printf -- '- Organize routes by domain/resource\n'
            printf -- '- Use middleware for cross-cutting concerns\n'
            printf -- '- Validate request input at the boundary\n'
            ;;
        fastapi)
            printf -- '- Use Pydantic models for request/response validation\n'
            printf -- '- Organize routes with APIRouter\n'
            printf -- '- Use dependency injection for shared logic\n'
            ;;
        django)
            printf -- '- Follow Django project structure conventions\n'
            printf -- '- Use class-based views where appropriate\n'
            printf -- '- Keep business logic in models or service layers\n'
            ;;
        flask)
            printf -- '- Use Blueprints for route organization\n'
            printf -- '- Keep view functions thin\n'
            ;;
        gin|echo|chi|fiber)
            printf -- '- Group routes by domain\n'
            printf -- '- Use middleware for auth, logging, etc.\n'
            printf -- '- Return structured error responses\n'
            ;;
        rails)
            printf -- '- Follow Rails conventions (Convention over Configuration)\n'
            printf -- '- Keep controllers thin; put logic in models/services\n'
            printf -- '- Use concerns for shared behavior\n'
            ;;
        spring)
            printf -- '- Follow Spring Boot project structure\n'
            printf -- '- Use constructor injection over field injection\n'
            printf -- '- Organize by feature/domain, not by layer\n'
            ;;
        actix|axum|rocket)
            printf -- '- Use extractors for request parsing\n'
            printf -- '- Handle errors with proper HTTP status codes\n'
            printf -- '- Keep handlers thin; delegate to service layer\n'
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Section: Testing
# ---------------------------------------------------------------------------
section_testing() {
    if [ -z "$TEST_FRAMEWORK" ] && [ "$TDD_PREFERENCE" = "none" ]; then
        return
    fi

    printf '## Testing\n\n'

    if [ -n "$TEST_FRAMEWORK" ]; then
        printf -- '- **Framework**: %s\n' "$TEST_FRAMEWORK"
    fi

    case "$TDD_PREFERENCE" in
        strict)
            printf -- '- **TDD**: Write tests FIRST, then implement. Follow red-green-refactor cycle.\n'
            ;;
        alongside)
            printf -- '- Write tests alongside implementation code\n'
            ;;
        after)
            printf -- '- Write tests after implementation to verify behavior\n'
            ;;
    esac

    # Test file naming conventions
    case "$LANGUAGE" in
        typescript|javascript)
            printf -- '- Test files: `*.test.ts` / `*.test.tsx` colocated with source\n'
            printf -- '- Use `describe/it` blocks with clear test names\n'
            ;;
        python)
            printf -- '- Test files: `test_*.py` in `tests/` directory\n'
            printf -- '- Use descriptive test function names: `test_should_<behavior>`\n'
            ;;
        go)
            printf -- '- Test files: `*_test.go` colocated with source\n'
            printf -- '- Use table-driven tests where appropriate\n'
            ;;
        rust)
            printf -- '- Unit tests: `#[cfg(test)]` module in source files\n'
            printf -- '- Integration tests: `tests/` directory\n'
            ;;
        ruby)
            if [ "$TEST_FRAMEWORK" = "rspec" ]; then
                printf -- '- Test files: `spec/` directory mirroring `app/` structure\n'
            else
                printf -- '- Test files: `test/` directory\n'
            fi
            ;;
    esac

    if [ -n "$CMD_TEST" ]; then
        printf -- '- Run tests: `%s`\n' "$CMD_TEST"
    fi

    printf '\n'
}

# ---------------------------------------------------------------------------
# Section: Git Workflow
# ---------------------------------------------------------------------------
section_git_workflow() {
    if [ "$COMMIT_STYLE" = "none" ] && [ "$BRANCH_STRATEGY" = "none" ]; then
        return
    fi

    printf '## Git Workflow\n\n'

    case "$COMMIT_STYLE" in
        conventional)
            printf '### Commit Messages\n\n'
            printf 'Use [Conventional Commits](https://www.conventionalcommits.org/):\n\n'
            printf '```\n'
            printf 'feat: add user authentication\n'
            printf 'fix: resolve race condition in queue processing\n'
            printf 'docs: update API documentation\n'
            printf 'refactor: extract validation into shared module\n'
            printf 'test: add integration tests for payment flow\n'
            printf 'chore: update dependencies\n'
            printf '```\n\n'
            ;;
        descriptive)
            printf '### Commit Messages\n\n'
            printf 'Write clear, descriptive commit messages:\n'
            printf -- '- Start with a verb in imperative mood (Add, Fix, Update, Remove)\n'
            printf -- '- Keep the subject line under 72 characters\n'
            printf -- '- Add a body for complex changes explaining the "why"\n\n'
            ;;
        ticket)
            printf '### Commit Messages\n\n'
            printf 'Prefix commits with ticket number:\n\n'
            printf '```\n'
            printf 'PROJ-123: Add user authentication\n'
            printf 'PROJ-456: Fix race condition in queue processing\n'
            printf '```\n\n'
            ;;
    esac

    case "$BRANCH_STRATEGY" in
        github-flow)
            printf '### Branching\n\n'
            printf -- '- Create feature branches from `main`\n'
            printf -- '- Use descriptive branch names: `feature/add-auth`, `fix/queue-race-condition`\n'
            printf -- '- Open PRs for review before merging\n'
            printf -- '- Delete branches after merge\n\n'
            ;;
        git-flow)
            printf '### Branching\n\n'
            printf -- '- `main` - production releases\n'
            printf -- '- `develop` - integration branch\n'
            printf -- '- `feature/*` - new features (branch from develop)\n'
            printf -- '- `release/*` - release preparation\n'
            printf -- '- `hotfix/*` - production fixes\n\n'
            ;;
        trunk)
            printf '### Branching\n\n'
            printf -- '- Work on short-lived branches (< 1 day)\n'
            printf -- '- Merge to `main` frequently\n'
            printf -- '- Use feature flags for incomplete features\n\n'
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Section: Gotchas
# ---------------------------------------------------------------------------
section_gotchas() {
    _has_gotchas=0

    # Check if we have any gotchas to show
    case "$LANGUAGE" in
        typescript|javascript|python|go|rust) _has_gotchas=1 ;;
    esac
    case "$FRAMEWORK" in
        nextjs|django|rails) _has_gotchas=1 ;;
    esac

    if [ "$_has_gotchas" -eq 0 ]; then return; fi

    printf '## Important Notes\n\n'

    case "$LANGUAGE" in
        typescript)
            printf -- '- Do not use `@ts-ignore` or `@ts-expect-error` without a comment explaining why\n'
            printf -- '- Prefer `unknown` over `any` when the type is truly unknown\n'
            ;;
        python)
            printf -- '- Always use virtual environments; never install packages globally\n'
            ;;
        go)
            printf -- '- Always check and handle errors; do not use `_` to discard errors\n'
            printf -- '- Run `go mod tidy` after adding/removing dependencies\n'
            ;;
        rust)
            printf -- '- Prefer `.expect("reason")` over `.unwrap()` for better error messages\n'
            printf -- '- Run `cargo clippy` before committing\n'
            ;;
    esac

    case "$FRAMEWORK" in
        nextjs)
            printf -- '- Avoid importing server-only code in client components\n'
            printf -- '- Use `next/image` for images and `next/link` for navigation\n'
            ;;
        django)
            printf -- '- Never commit `SECRET_KEY` or database credentials\n'
            printf -- '- Run migrations after model changes: `python manage.py makemigrations && python manage.py migrate`\n'
            ;;
        rails)
            printf -- '- Run `rails db:migrate` after pulling changes with new migrations\n'
            printf -- '- Never commit `config/master.key` or `config/credentials.yml.enc`\n'
            ;;
    esac

    printf '\n'
}

# ---------------------------------------------------------------------------
# Generate .claude/settings.json
# ---------------------------------------------------------------------------
generate_settings_json() {
    _allow_cmds=""
    _deny_patterns=""

    # Build allow list based on detected commands
    _allow_list=""
    for _cmd in "$CMD_BUILD" "$CMD_DEV" "$CMD_TEST" "$CMD_LINT" "$CMD_FORMAT"; do
        if [ -n "$_cmd" ]; then
            if [ -z "$_allow_list" ]; then
                _allow_list="$_cmd"
            else
                _allow_list="$_allow_list|$_cmd"
            fi
        fi
    done

    # Add language-specific safe commands
    case "$LANGUAGE" in
        typescript|javascript)
            _pkg_exec=""
            case "$PKG_MANAGER" in
                npm)  _pkg_exec="npx" ;;
                yarn) _pkg_exec="yarn" ;;
                pnpm) _pkg_exec="pnpm exec" ;;
                bun)  _pkg_exec="bunx" ;;
            esac
            if [ -n "$_pkg_exec" ]; then
                _allow_list="$_allow_list|$_pkg_exec tsc --noEmit"
            fi
            ;;
        go)
            _allow_list="$_allow_list|go mod tidy"
            ;;
        rust)
            _allow_list="$_allow_list|cargo check"
            ;;
    esac

    # Output JSON
    json_object_start
    printf '  "permissions": {\n'
    printf '    "allow": [\n'

    _first=1
    _OLD_IFS="$IFS"
    IFS="|"
    for _cmd in $_allow_list; do
        if [ -z "$_cmd" ]; then continue; fi
        if [ "$_first" -eq 1 ]; then
            _first=0
        else
            printf ',\n'
        fi
        printf '      %s' "$(json_string "$_cmd")"
    done
    IFS="$_OLD_IFS"

    printf '\n    ],\n'
    printf '    "deny": [\n'
    printf '      "cat .env*",\n'
    printf '      "cat *secret*",\n'
    printf '      "cat *credential*",\n'
    printf '      "rm -rf /",\n'
    printf '      "rm -rf ~"\n'
    printf '    ]\n'
    printf '  }\n'
    json_object_end
}

# ---------------------------------------------------------------------------
# Generate a skill file
# ---------------------------------------------------------------------------
generate_skill() {
    _skill_name="$1"

    case "$_skill_name" in
        */review*)   _gen_skill_review ;;
        */test*)     _gen_skill_test ;;
        */fix-issue*) _gen_skill_fix_issue ;;
        */deploy*)   _gen_skill_deploy ;;
        */tdd*)      _gen_skill_tdd ;;
        */document*) _gen_skill_document ;;
        */component*) _gen_skill_component ;;
        */page*)     _gen_skill_page ;;
        */endpoint*) _gen_skill_endpoint ;;
        */middleware*) _gen_skill_middleware ;;
        */model*)    _gen_skill_model ;;
    esac
}

_gen_skill_review() {
    cat << 'SKILL_EOF'
# Code Review

Review the code changes for:

1. **Correctness**: Does the code do what it's supposed to?
2. **Edge cases**: Are boundary conditions handled?
3. **Error handling**: Are errors caught and handled appropriately?
4. **Performance**: Any obvious performance issues?
5. **Security**: Any security concerns (injection, XSS, etc.)?
6. **Readability**: Is the code clear and well-organized?
7. **Tests**: Are there adequate tests for the changes?

Provide specific, actionable feedback with file paths and line numbers.
SKILL_EOF
}

_gen_skill_test() {
    printf '# Run Tests\n\n'
    if [ -n "$CMD_TEST" ]; then
        printf 'Run the test suite:\n\n'
        printf '```sh\n%s\n```\n\n' "$CMD_TEST"
    fi
    cat << 'SKILL_EOF'
If tests fail:
1. Read the error output carefully
2. Identify the failing test and the assertion
3. Look at the relevant source code
4. Fix the issue (not the test, unless the test is wrong)
5. Re-run to verify the fix
SKILL_EOF
}

_gen_skill_fix_issue() {
    cat << 'SKILL_EOF'
# Fix Issue

Given a GitHub issue number or description:

1. Understand the bug/feature request fully
2. Find the relevant code
3. Implement the fix/feature with minimal changes
4. Write or update tests
5. Verify the fix resolves the issue
6. Summarize what was changed and why
SKILL_EOF
}

_gen_skill_deploy() {
    printf '# Pre-Deploy Checklist\n\n'
    printf 'Before deploying, verify:\n\n'
    if [ -n "$CMD_TEST" ]; then
        printf -- '- [ ] Tests pass: `%s`\n' "$CMD_TEST"
    fi
    if [ -n "$CMD_LINT" ]; then
        printf -- '- [ ] Linting passes: `%s`\n' "$CMD_LINT"
    fi
    if [ -n "$CMD_BUILD" ]; then
        printf -- '- [ ] Build succeeds: `%s`\n' "$CMD_BUILD"
    fi
    cat << 'SKILL_EOF'
- [ ] No secrets or credentials in code
- [ ] Environment variables documented
- [ ] Database migrations ready (if applicable)
- [ ] Breaking changes documented
- [ ] CHANGELOG updated
SKILL_EOF
}

_gen_skill_tdd() {
    cat << 'SKILL_EOF'
# TDD Cycle

Follow the Red-Green-Refactor cycle:

1. **RED**: Write a failing test that describes the desired behavior
2. **GREEN**: Write the minimum code to make the test pass
3. **REFACTOR**: Clean up the code while keeping tests green

Rules:
- Never write production code without a failing test
- Write only enough test code to fail
- Write only enough production code to pass
- Refactor only when all tests pass
SKILL_EOF
}

_gen_skill_document() {
    cat << 'SKILL_EOF'
# Generate Documentation

For the specified code:

1. Add/update JSDoc, docstrings, or doc comments for public APIs
2. Include parameter descriptions and return types
3. Add usage examples where helpful
4. Update README if the public API changed
5. Keep documentation concise and accurate
SKILL_EOF
}

_gen_skill_component() {
    printf '# Create Component\n\n'
    printf 'Create a new UI component following project conventions:\n\n'
    case "$FRAMEWORK" in
        nextjs|react)
            printf -- '1. Create component file in the appropriate directory\n'
            printf -- '2. Use functional component with TypeScript props interface\n'
            printf -- '3. Add unit tests\n'
            printf -- '4. Export from the nearest index/barrel file if one exists\n'
            ;;
        vue)
            printf -- '1. Create `.vue` SFC with `<script setup lang="ts">`\n'
            printf -- '2. Define props with `defineProps`\n'
            printf -- '3. Add unit tests\n'
            ;;
        svelte)
            printf -- '1. Create `.svelte` component file\n'
            printf -- '2. Define props with `export let` or `$props()`\n'
            printf -- '3. Add unit tests\n'
            ;;
        *)
            printf -- '1. Create component following project patterns\n'
            printf -- '2. Add props/interface definitions\n'
            printf -- '3. Add unit tests\n'
            ;;
    esac
}

_gen_skill_page() {
    printf '# Create Page/Route\n\n'
    case "$FRAMEWORK" in
        nextjs)
            printf 'Create a new Next.js route:\n\n'
            printf -- '1. Create `app/<route>/page.tsx`\n'
            printf -- '2. Add layout if needed: `app/<route>/layout.tsx`\n'
            printf -- '3. Use Server Components by default\n'
            printf -- '4. Add loading/error states if appropriate\n'
            ;;
        *)
            printf 'Create a new page/route following project conventions.\n'
            ;;
    esac
}

_gen_skill_endpoint() {
    printf '# Create API Endpoint\n\n'
    case "$FRAMEWORK" in
        fastapi)
            printf 'Create a new FastAPI endpoint:\n\n'
            printf -- '1. Define Pydantic request/response models\n'
            printf -- '2. Create route handler with proper HTTP method\n'
            printf -- '3. Add input validation\n'
            printf -- '4. Add error handling with appropriate status codes\n'
            printf -- '5. Write tests\n'
            ;;
        express|fastify|hono)
            printf 'Create a new API endpoint:\n\n'
            printf -- '1. Define request/response types\n'
            printf -- '2. Create route handler\n'
            printf -- '3. Add input validation\n'
            printf -- '4. Add error handling\n'
            printf -- '5. Write tests\n'
            ;;
        django)
            printf 'Create a new Django view/endpoint:\n\n'
            printf -- '1. Add URL pattern in urls.py\n'
            printf -- '2. Create view (function or class-based)\n'
            printf -- '3. Add serializer if using DRF\n'
            printf -- '4. Write tests\n'
            ;;
        *)
            printf 'Create a new API endpoint following project conventions.\n'
            ;;
    esac
}

_gen_skill_middleware() {
    cat << 'SKILL_EOF'
# Create Middleware

Create a new middleware component:

1. Define the middleware function/class
2. Handle the request/response cycle
3. Add error handling
4. Register in the middleware chain
5. Write tests
SKILL_EOF
}

_gen_skill_model() {
    printf '# Create Data Model\n\n'
    case "$FRAMEWORK" in
        fastapi)
            printf 'Create a new Pydantic/SQLAlchemy model:\n\n'
            printf -- '1. Define Pydantic schema for validation\n'
            printf -- '2. Create database model if applicable\n'
            printf -- '3. Add relationships and constraints\n'
            printf -- '4. Create migration\n'
            printf -- '5. Write tests\n'
            ;;
        django)
            printf 'Create a new Django model:\n\n'
            printf -- '1. Define model class with fields\n'
            printf -- '2. Add Meta class if needed\n'
            printf -- '3. Create and run migrations\n'
            printf -- '4. Add admin registration\n'
            printf -- '5. Write tests\n'
            ;;
        *)
            printf 'Create a new data model following project conventions.\n'
            ;;
    esac
}

# ---------------------------------------------------------------------------
# Write all generated files
# ---------------------------------------------------------------------------
write_all_files() {
    # Write CLAUDE.md
    _claude_md="$(generate_claude_md)"
    write_file "CLAUDE.md" "$_claude_md"
    success "Created CLAUDE.md"

    # Write .claude/settings.json
    _settings="$(generate_settings_json)"
    ensure_dir ".claude"
    write_file ".claude/settings.json" "$_settings"
    success "Created .claude/settings.json"

    # Write selected skills
    if [ -n "$SELECTED_SKILLS" ]; then
        ensure_dir ".claude/skills"
        _OLD_IFS="$IFS"
        IFS="|"
        for _skill_entry in $SELECTED_SKILLS; do
            # Extract skill name from entry like "/review - Code review"
            _skill_cmd="$(printf '%s' "$_skill_entry" | sed 's/ -.*//' | sed 's|^/||')"
            if [ -n "$_skill_cmd" ]; then
                _skill_content="$(generate_skill "$_skill_cmd")"
                if [ -n "$_skill_content" ]; then
                    write_file ".claude/skills/${_skill_cmd}.md" "$_skill_content"
                    success "Created .claude/skills/${_skill_cmd}.md"
                fi
            fi
        done
        IFS="$_OLD_IFS"
    fi

    # Offer to add to .gitignore
    if [ -f ".gitignore" ]; then
        if ! grep -q "settings.local.json" .gitignore 2>/dev/null; then
            if confirm "Add .claude/settings.local.json to .gitignore?"; then
                printf '\n# Claude Code local settings\n.claude/settings.local.json\n' >> .gitignore
                success "Updated .gitignore"
            fi
        fi
    fi
}
