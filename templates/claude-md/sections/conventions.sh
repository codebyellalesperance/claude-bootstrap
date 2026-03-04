#!/bin/sh
# Template: Coding conventions section for CLAUDE.md

tmpl_section_conventions() {
    _lang="$1"
    _framework="$2"
    _naming="$3"

    printf '## Coding Conventions\n\n'
    [ -n "$_naming" ] && printf -- '- **Naming**: %s\n' "$_naming"

    # Language-specific
    case "$_lang" in
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
    esac

    # Framework-specific
    case "$_framework" in
        nextjs)
            printf -- '- Use App Router; prefer Server Components\n'
            printf -- '- Co-locate components near their routes\n'
            ;;
        react)
            printf -- '- Use functional components with hooks\n'
            printf -- '- Keep components small and focused\n'
            ;;
        fastapi)
            printf -- '- Use Pydantic models for validation\n'
            printf -- '- Organize routes with APIRouter\n'
            ;;
        django)
            printf -- '- Follow Django conventions\n'
            printf -- '- Keep controllers thin\n'
            ;;
    esac

    printf '\n'
}
