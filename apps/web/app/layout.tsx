import { DesignSystemProvider } from "@repo/design-system";
import { cn } from "@repo/design-system/lib/utils";
import type { Metadata } from "next";
import { fonts } from "@/lib/fonts";
import "./globals.css";

export const metadata: Metadata = {
  title: "MicAway — Your mic follows your attention",
  description:
    "AirPods-aware microphone control for macOS. Look away and MicAway keeps side conversations out of your voice apps.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html className={cn(fonts, "scroll-smooth")} lang="en" suppressHydrationWarning>
      <body className="min-h-dvh bg-background text-foreground" suppressHydrationWarning>
        <DesignSystemProvider attribute="class" defaultTheme="light" enableSystem>
          {children}
        </DesignSystemProvider>
      </body>
    </html>
  );
}
