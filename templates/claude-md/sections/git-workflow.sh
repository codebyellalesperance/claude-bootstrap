#!/bin/sh
# Template: Git workflow section for CLAUDE.md

tmpl_section_git_workflow() {
    _commit_style="$1"
    _branch_strategy="$2"

    [ "$_commit_style" = "none" ] && [ "$_branch_strategy" = "none" ] && return

    printf '## Git Workflow\n\n'

    case "$_commit_style" in
        conventional)
            printf '### Commit Messages\n\n'
            printf 'Use Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`\n\n'
            ;;
        descriptive)
            printf '### Commit Messages\n\n'
            printf 'Imperative mood, under 72 chars. Add body for complex changes.\n\n'
            ;;
        ticket)
            printf '### Commit Messages\n\n'
            printf 'Prefix with ticket number: `PROJ-123: description`\n\n'
            ;;
    esac

    case "$_branch_strategy" in
        github-flow)
            printf '### Branching\n\n'
            printf -- '- Feature branches from `main`, PRs for review, delete after merge\n\n'
            ;;
        git-flow)
            printf '### Branching\n\n'
            printf -- '- `main` (prod), `develop` (integration), `feature/*`, `release/*`, `hotfix/*`\n\n'
            ;;
        trunk)
            printf '### Branching\n\n'
            printf -- '- Short-lived branches, merge to `main` frequently, use feature flags\n\n'
            ;;
    esac
}
