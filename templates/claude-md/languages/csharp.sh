#!/bin/sh
# Language fragment: C#

tmpl_lang_csharp() {
    cat << 'EOF'
- Follow .NET naming conventions
- PascalCase for public members, camelCase for private
- Use nullable reference types
- Prefer pattern matching where appropriate
EOF
}
