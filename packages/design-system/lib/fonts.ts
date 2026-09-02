import { cn } from "@repo/design-system/lib/utils";
import { Plus_Jakarta_Sans } from "next/font/google";

/**
 * Shared fallback font configuration for product surfaces.
 */
const plusJakarta = Plus_Jakarta_Sans({
  subsets: ["latin"],
  variable: "--font-sans",
  display: "swap",
  weight: ["400", "500", "600", "700"],
});

export const fonts = cn(
  plusJakarta.variable,
  "touch-manipulation font-sans antialiased"
);
