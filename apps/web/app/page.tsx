import { BrandLogo } from "@repo/design-system/components/brand/logo";
import Link from "next/link";

export default function HomePage() {
  return (
    <main className="mx-auto flex min-h-dvh max-w-3xl flex-col justify-center gap-8 px-6 py-16">
      <BrandLogo title="Studio Web" />
      <div className="space-y-3">
        <p className="text-sm font-medium tracking-wide text-muted-foreground uppercase">
          Marketing shell
        </p>
        <h1 className="sk-display text-5xl leading-tight text-foreground md:text-6xl">
          Ship a site. Own the look.
        </h1>
        <p className="max-w-xl text-lg text-muted-foreground">
          This app uses its own fonts and CSS tokens. Fork the kit, then rewrite{" "}
          <code className="rounded bg-muted px-1.5 py-0.5 text-sm">
            styles/theme.css
          </code>{" "}
          and{" "}
          <code className="rounded bg-muted px-1.5 py-0.5 text-sm">
            lib/fonts.ts
          </code>{" "}
          so the next product does not look like this one.
        </p>
      </div>
      <div className="flex flex-wrap gap-3">
        <Link
          className="rounded-lg bg-primary px-4 py-2.5 text-sm font-medium text-primary-foreground"
          href="/docs"
        >
          Theming notes
        </Link>
        <a
          className="rounded-lg border border-border px-4 py-2.5 text-sm font-medium"
          href="http://localhost:3000"
        >
          Open product app →
        </a>
      </div>
    </main>
  );
}
