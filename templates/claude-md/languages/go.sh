#!/bin/sh
# Language fragment: Go

tmpl_lang_go() {
    cat << 'EOF'
- Follow Effective Go guidelines
- Handle errors explicitly; do not ignore error returns
- Keep functions short and focused
- Use short variable names in limited scope
- Run `go mod tidy` after dependency changes
EOF
}
