# 03 — Ship

## Local

```bash
pnpm install
pnpm dev:web   # :3001
pnpm dev:app   # :3000
pnpm build
```

## Vercel

1. Import the GitHub repo.
2. Root directory: `apps/web` or `apps/app` (separate projects).
3. Install: `pnpm install` (from monorepo root — set Root Directory carefully or use `cd ../.. && pnpm install` only if Vercel root is the app).
4. Build: `pnpm --filter web build` / `pnpm --filter app build`.

## Domains

- Document production + www + previews here per product.

## Checklist

- [ ] Theme + fonts unique to this product
- [ ] Brand mark/wordmark set
- [ ] Env vars documented (no secrets in git)
- [ ] Analytics / auth wired if needed
