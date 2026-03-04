#!/bin/sh
# Framework fragment: Rails

tmpl_fw_rails() {
    cat << 'EOF'
- Follow Rails conventions (Convention over Configuration)
- Keep controllers thin; put logic in models/services
- Use concerns for shared behavior
- Run `rails db:migrate` after pulling new migrations
- Never commit `config/master.key`
EOF
}
