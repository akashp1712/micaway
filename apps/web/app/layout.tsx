import { DesignSystemProvider } from "@repo/design-system";
import { cn } from "@repo/design-system/lib/utils";
import type { Metadata } from "next";
import { fonts } from "@/lib/fonts";
import "./globals.css";

const siteUrl = "https://micaway.akashpanchal.com";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: "MicAway — Turn to answer. The call mutes.",
  description:
    "Turn your head away from the Mac during a call and the mic mutes. Face the Mac and it comes back. AirPods motion, local only.",
  alternates: {
    canonical: "/",
  },
  openGraph: {
    url: siteUrl,
    siteName: "MicAway",
    type: "website",
  },
  icons: {
    icon: "/brand/micaway-app-icon.png",
    apple: "/brand/micaway-app-icon.png",
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html
      className={cn(fonts, "scroll-smooth")}
      lang="en"
      suppressHydrationWarning
    >
      <head>
        <link href="/product.md" rel="alternate" type="text/markdown" />
        <link href="/llms.txt" rel="alternate" type="text/plain" />
      </head>
      <body
        className="min-h-dvh bg-background text-foreground"
        suppressHydrationWarning
      >
        <DesignSystemProvider
          attribute="class"
          defaultTheme="light"
          enableSystem
        >
          {children}
        </DesignSystemProvider>
      </body>
    </html>
  );
}
