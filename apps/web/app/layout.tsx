import { DesignSystemProvider } from "@repo/design-system";
import { cn } from "@repo/design-system/lib/utils";
import type { Metadata } from "next";
import { fonts } from "@/lib/fonts";
import "./globals.css";

export const metadata: Metadata = {
  title: "MicAway — Turn your head. Mute the mic.",
  description:
    "Open-source, AirPods-aware microphone privacy for macOS. Face your Mac to dictate; turn away to mute.",
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
