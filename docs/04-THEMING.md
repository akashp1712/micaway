# 04 — Theming (caution)

**Shared UI ≠ shared look.** The kit ships primitives (buttons, dialogs, tokens slots). Each product must own identity.

## What is shared

- `@repo/design-system` components and base CSS variables
- Neutral zinc defaults (fallback only)

## What must differ per product

| Slot | Where | Rule |
|------|--------|------|
| Colors / radius / shadows | `apps/*/styles/theme.css` | Rewrite; don't inherit Evercall cream or sibling product indigo |
| Fonts | `apps/*/lib/fonts.ts` | Different faces for web vs app, and across products |
| Logo | `BrandLogo` / `BrandMark` `markPath` + title | New mark path + wordmark |
| Display type classes | app `globals.css` | Optional product-specific utility classes |

## Anti-patterns

- Copying Evercall Capture mark or hospitality palette into a new product
- One global font for every app in the studio
- Shipping kit zinc defaults unchanged as "the brand"
- Purple-on-white / cream+terracotta / broadsheet clones by default — pick a direction on purpose

## Fork checklist

1. Delete demo copy on `apps/web` and `apps/app` home pages
2. Replace both `theme.css` files
3. Replace both `fonts.ts` files (ideally different stacks)
4. Set brand title + SVG path
5. Screenshot side-by-side with another studio product — they must not look like reskins
