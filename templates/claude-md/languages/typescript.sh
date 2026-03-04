#!/bin/sh
# Language fragment: TypeScript

tmpl_lang_typescript() {
    cat << 'EOF'
- Use TypeScript strict mode; avoid `any` types
- Prefer `interface` over `type` for object shapes
- Use explicit return types on exported functions
- Prefer `unknown` over `any` when the type is truly unknown
- Do not use `@ts-ignore` without explaining why
EOF
}
