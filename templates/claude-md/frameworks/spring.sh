#!/bin/sh
# Framework fragment: Spring Boot

tmpl_fw_spring() {
    cat << 'EOF'
- Follow Spring Boot project structure
- Use constructor injection over field injection
- Organize by feature/domain, not by layer
- Use @Valid for request validation
EOF
}
