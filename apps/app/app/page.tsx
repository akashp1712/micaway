import { BrandLogo } from "@repo/design-system/components/brand/logo";
import { ModeToggle } from "@repo/design-system/components/mode-toggle";

const APP_MARK = "M6 8h8v4H10v12H6V8zm12 0h8v16h-4V16h-4V8zm4 4h-4v4h4v-4z";

export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-dvh max-w-3xl flex-col gap-10 px-6 py-16">
      <header className="flex items-center justify-between">
        <BrandLogo markPath={APP_MARK} title="Studio App" />
        <ModeToggle />
      </header>
      <div className="space-y-3">
        <p className="font-mono text-xs tracking-widest text-muted-foreground uppercase">
          Product shell · :3000
        </p>
        <h1 className="text-4xl font-semibold tracking-tight md:text-5xl">
          Dashboard-ready. Not the marketing twin.
        </h1>
        <p className="max-w-xl text-muted-foreground">
          Space Grotesk + cool indigo tokens. The marketing app on :3001 uses a
          different type stack and warm palette on purpose.
        </p>
      </div>
      <div className="rounded-lg border border-border bg-card p-5 shadow-[var(--shadow-elevation)]">
        <p className="font-mono text-sm text-muted-foreground">
          theme → apps/app/styles/theme.css
          <br />
          fonts → apps/app/lib/fonts.ts
        </p>
      </div>
    </main>
  );
}
