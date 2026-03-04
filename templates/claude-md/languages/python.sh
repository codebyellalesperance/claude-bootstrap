#!/bin/sh
# Language fragment: Python

tmpl_lang_python() {
    cat << 'EOF'
- Follow PEP 8 style guide
- Use type hints for function signatures
- Prefer f-strings for string formatting
- Always use virtual environments
- Use `from __future__ import annotations` for forward references
EOF
}
