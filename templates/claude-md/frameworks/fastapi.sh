#!/bin/sh
# Framework fragment: FastAPI

tmpl_fw_fastapi() {
    cat << 'EOF'
- Use Pydantic models for request/response validation
- Organize routes with APIRouter
- Use dependency injection for shared logic
- Return proper HTTP status codes
EOF
}
