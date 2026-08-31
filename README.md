# studio-kit

Reusable Turborepo starter for small product studios: **shared UI primitives**, **per-app themes**, **ops + skills routing**.

Not a visual brand. Evercall, OneCue, and the next app should fork this kit and **look different**.

## What's inside

```
apps/web                 marketing shell (:3001) — warm editorial demo theme
apps/app                 product shell (:3000) — cool utility demo theme
packages/design-system   shadcn-style primitives + BrandLogo slots
packages/next-config     shared Next defaults
packages/typescript-config
ops/                     outreach · marketing · social · strategy
.agents/skills/          landing system + interface craft
docs/                    product / system / ship / theming
```

## Theming caution

Read [docs/04-THEMING.md](./docs/04-THEMING.md).

Each app owns:

- `styles/theme.css` — colors, radius, shadows
- `lib/fonts.ts` — typefaces (web ≠ app in the demos on purpose)
- `BrandLogo` title + `markPath`

## Quick start

```bash
pnpm install
pnpm dev          # web + app
pnpm build
```

## Fork a new product

1. Use as GitHub template (or copy the folder).
2. Rename root `package.json` name + app metadata.
3. Rewrite themes/fonts/brand for **that** product only.
4. Fill `docs/01-PRODUCT.md` and wire Vercel per [docs/03-SHIP.md](./docs/03-SHIP.md).
5. Symlink money / Corey / ams skills as needed — see [ops/SKILLS.md](./ops/SKILLS.md).

## Skills

Bundled: `personal-landing-system`, `make-interfaces-feel-better`.

Install money/ams/Corey from their repos; don't vendor the entire packs into every fork.
