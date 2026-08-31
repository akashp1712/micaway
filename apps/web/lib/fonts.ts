import { cn } from "@repo/design-system/lib/utils";
import { DM_Sans, Instrument_Serif } from "next/font/google";

/**
 * Marketing site fonts — replace when forking a product.
 * Deliberately different from apps/app so surfaces don't look cloned.
 */
const sans = DM_Sans({
  subsets: ["latin"],
  variable: "--font-sans",
  display: "swap",
  weight: ["400", "500", "600", "700"],
});

const display = Instrument_Serif({
  subsets: ["latin"],
  variable: "--font-display",
  display: "swap",
  weight: ["400"],
});

export const fonts = cn(
  sans.variable,
  display.variable,
  "touch-manipulation font-sans antialiased"
);
