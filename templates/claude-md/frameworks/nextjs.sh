#!/bin/sh
# Framework fragment: Next.js

tmpl_fw_nextjs() {
    cat << 'EOF'
- Use App Router (app/) unless the project uses Pages Router
- Prefer Server Components by default; use "use client" only when needed
- Co-locate components, tests, and styles near their routes
- Use `next/image` for images and `next/link` for navigation
- Avoid importing server-only code in client components
EOF
}
