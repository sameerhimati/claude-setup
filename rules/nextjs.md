---
description: Next.js conventions. Scoped to Next.js repos.
paths:
  - "**/next.config.*"
  - "**/app/**"
  - "**/*.tsx"
---

# Next.js (App Router)

- App Router by default. Server Components unless interactivity is needed (`"use client"` only where required).
- Data fetching in server components; mutations via server actions or route handlers.
- Tailwind + shadcn/ui; match existing component patterns.
- Keep client bundles lean — no gratuitous `"use client"` or heavy client deps.
- Prisma + Postgres where a DB is used (Bun in some repos — check package.json).
