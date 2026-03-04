#!/bin/sh
# Framework fragment: Gin

tmpl_fw_gin() {
    cat << 'EOF'
- Group routes by domain
- Use middleware for auth, logging, recovery
- Return structured JSON error responses
- Use binding tags for request validation
EOF
}
