# Skill packs — routing (studio-kit)

Install globally (or symlink into `.agents/skills/`). Do **not** dump every vendor skill into every product repo — link what you need.

## Sources

| Pack | Source | Prefix / notes |
|------|--------|----------------|
| Show Me The Money | [iamzifei/show-me-the-money](https://github.com/iamzifei/show-me-the-money) | `money*` |
| Marketing Skills (Corey) | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | craft: cro, copywriting, offers, … |
| AI Marketing Skills (Eric) | [ericosiu/ai-marketing-skills](https://github.com/ericosiu/ai-marketing-skills) | `ams-*` pipelines |

Local clones (optional): `~/workspace/skills-src/{show-me-the-money,marketingskills,ai-marketing-skills}`

## Mix, don't pick one

- **Corey** = playbooks (landing, CRO, community, SMS craft)
- **ams-*** = runnable ops (outbound engines, clip pipelines, SEO ops)
- **money*** = founder business OS (strategy → outreach → retro)

```
Weekly "what next"           →  /money or money-strategy
Landing / hero / CRO         →  copywriting, cro, offers
Community / FB               →  community-marketing
Short-form / video ops       →  video + ams-short-form-pipeline
Cold SMS / email             →  sms, cold-email + money-outreach
Instantly / outbound stack   →  ams-outbound-engine (when tooling exists)
```

## Kit-bundled skills

Already in `.agents/skills/`:

- `personal-landing-system` — distill → design → build landings
- `make-interfaces-feel-better` — type, surfaces, motion, performance

## Per-product ops folders

Put product-specific notes under:

- `ops/outreach/`
- `ops/marketing/`
- `ops/social/`
- `ops/strategy/`

Keep Evercall plumber specifics out of this template.
