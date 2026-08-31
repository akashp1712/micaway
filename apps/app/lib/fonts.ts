import { cn } from "@repo/design-system/lib/utils";
import { IBM_Plex_Mono, Space_Grotesk } from "next/font/google";

/**
 * Product app fonts — different family set from apps/web on purpose.
 */
const sans = Space_Grotesk({
  subsets: ["latin"],
  variable: "--font-sans",
  display: "swap",
  weight: ["400", "500", "600", "700"],
});

const mono = IBM_Plex_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
  display: "swap",
  weight: ["400", "500"],
});

export const fonts = cn(
  sans.variable,
  mono.variable,
  "touch-manipulation font-sans antialiased"
);
