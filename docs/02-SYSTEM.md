# 02 — System

## Monorepo layout

```
apps/web     marketing / public site
apps/app     authenticated product UI
packages/    design-system, next-config, typescript-config
docs/        product / system / ship / theming
```

## Integration rule

Prefer HTTPS/JSON between surfaces. Do not couple marketing web to product DB unless needed.

## Agents / voice (optional)

If you add a LiveKit (or similar) agent, keep it in a sibling app/repo and integrate over APIs — same pattern as Evercall.
