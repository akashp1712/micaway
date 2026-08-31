import { cn } from "@repo/design-system/lib/utils";
import { motion } from "motion/react";

type LogoProps = {
  className?: string;
  markClassName?: string;
  withWordmark?: boolean;
  title?: string;
  wordmarkClassName?: string;
  /** Override SVG path per product */
  markPath?: string;
};

/** Neutral geometric mark — replace per brand. */
export const DEFAULT_MARK_PATH =
  "M8 6h16a4 4 0 0 1 4 4v12a4 4 0 0 1-4 4H8a4 4 0 0 1-4-4V10a4 4 0 0 1 4-4z";

export function BrandMark({
  className,
  title,
  animate = false,
  path = DEFAULT_MARK_PATH,
}: {
  className?: string;
  title?: string;
  animate?: boolean;
  path?: string;
}) {
  const decorative = title === undefined;
  return (
    <svg
      aria-hidden={decorative ? true : undefined}
      aria-label={decorative ? undefined : title}
      className={cn("size-8", className)}
      fill="none"
      role={decorative ? undefined : "img"}
      viewBox="0 0 32 32"
      xmlns="http://www.w3.org/2000/svg"
    >
      {!decorative && <title>{title}</title>}
      {animate ? (
        <motion.path
          animate={{ opacity: 1, scale: 1 }}
          d={path}
          fill="currentColor"
          initial={{ opacity: 0, scale: 0.92 }}
          style={{ transformOrigin: "16px 16px" }}
          transition={{ duration: 0.45, ease: [0.2, 0, 0, 1] }}
        />
      ) : (
        <path d={path} fill="currentColor" />
      )}
    </svg>
  );
}

export function BrandLogo({
  className,
  markClassName,
  withWordmark = true,
  title = "Product",
  wordmarkClassName,
  markPath,
}: LogoProps) {
  return (
    <span className={cn("inline-flex items-center gap-2.5", className)}>
      <span
        className={cn(
          "flex size-9 shrink-0 items-center justify-center rounded-[10px] bg-foreground text-background shadow-[var(--shadow-elevation)]",
          markClassName
        )}
      >
        <BrandMark className="size-[72%]" path={markPath} />
      </span>
      {withWordmark ? (
        <span
          className={cn(
            "whitespace-nowrap font-semibold text-2xl text-foreground tracking-tight",
            wordmarkClassName
          )}
        >
          {title}
        </span>
      ) : (
        <span className="sr-only">{title}</span>
      )}
    </span>
  );
}
