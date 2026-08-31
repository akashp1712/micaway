import { DesignSystemProvider } from "@repo/design-system";
import { cn } from "@repo/design-system/lib/utils";
import type { Metadata } from "next";
import { fonts } from "@/lib/fonts";
import "./globals.css";

export const metadata: Metadata = {
  title: "Hear Me Not — A boundary for voice-first work",
  description: "AirPods-aware microphone privacy for macOS. Turn toward someone and keep side conversations out of your voice apps.",
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
