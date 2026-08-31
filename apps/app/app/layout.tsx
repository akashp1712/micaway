import { DesignSystemProvider } from "@repo/design-system";
import { cn } from "@repo/design-system/lib/utils";
import type { Metadata } from "next";
import { fonts } from "@/lib/fonts";
import "./globals.css";

export const metadata: Metadata = {
  title: "Studio Kit — App",
  description: "Product shell template. Theme and fonts are local to this app.",
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
          defaultTheme="system"
          enableSystem
        >
          {children}
        </DesignSystemProvider>
      </body>
    </html>
  );
}
