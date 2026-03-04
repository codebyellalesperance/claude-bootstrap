#!/bin/sh
# Language fragment: Rust

tmpl_lang_rust() {
    cat << 'EOF'
- Follow Rust API Guidelines
- Prefer `Result` over `panic!` for error handling
- Use `clippy` warnings as guidance
- Prefer `.expect("reason")` over `.unwrap()`
- Run `cargo clippy` before committing
EOF
}
