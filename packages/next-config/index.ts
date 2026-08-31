import withBundleAnalyzer from "@next/bundle-analyzer";
import type { NextConfig } from "next";

/** Shared Next.js defaults for Vercel monorepos. */
export const config: NextConfig = {
  poweredByHeader: false,
  reactStrictMode: true,
  transpilePackages: ["@repo/design-system"],
  images: {
    formats: ["image/avif", "image/webp"],
    remotePatterns: [{ protocol: "https", hostname: "img.clerk.com" }],
  },
  experimental: {
    optimizePackageImports: [
      "lucide-react",
      "motion",
      "radix-ui",
      "@repo/design-system",
    ],
  },
};

export const withAnalyzer = (sourceConfig: NextConfig): NextConfig =>
  withBundleAnalyzer()(sourceConfig);
