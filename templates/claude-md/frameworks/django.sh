#!/bin/sh
# Framework fragment: Django

tmpl_fw_django() {
    cat << 'EOF'
- Follow Django project structure conventions
- Use class-based views where appropriate
- Keep business logic in models or service layers
- Never commit SECRET_KEY or database credentials
- Run migrations after model changes
EOF
}
