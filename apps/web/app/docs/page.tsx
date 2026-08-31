import Link from "next/link";

export default function DocsPage() {
  return (
    <main className="mx-auto max-w-2xl space-y-6 px-6 py-16">
      <Link
        className="text-sm text-muted-foreground hover:text-foreground"
        href="/"
      >
        ← Home
      </Link>
      <h1 className="sk-display text-4xl">Per-product theming</h1>
      <ol className="list-decimal space-y-3 pl-5 text-muted-foreground">
        <li>Copy this monorepo (or use as GitHub template).</li>
        <li>Rename package + app titles.</li>
        <li>
          Replace{" "}
          <code className="text-foreground">apps/*/styles/theme.css</code>.
        </li>
        <li>
          Replace <code className="text-foreground">apps/*/lib/fonts.ts</code>{" "}
          (different faces per surface).
        </li>
        <li>
          Pass a custom mark path into{" "}
          <code className="text-foreground">BrandLogo</code>.
        </li>
      </ol>
      <p className="text-sm text-muted-foreground">
        Kit UI primitives stay shared. Visual identity must not.
      </p>
    </main>
  );
}
