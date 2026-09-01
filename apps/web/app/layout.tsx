import { DesignSystemProvider } from "@repo/design-system";
import { cn } from "@repo/design-system/lib/utils";
import type { Metadata } from "next";
import { fonts } from "@/lib/fonts";
import "./globals.css";

const siteUrl = "https://micaway.akashpanchal.com";

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: "MicAway — Not every word is a prompt",
  description:
    "The missing mute gesture for continuous voice agents. Look away to keep side conversations out; face your Mac to continue.",
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
