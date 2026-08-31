import { cn } from "@repo/design-system/lib/utils";
import { type HTMLMotionProps, motion } from "motion/react";
import React from "react";

export const ShinyButton = React.forwardRef<
  HTMLButtonElement,
  HTMLMotionProps<"button"> & { children: React.ReactNode }
>(({ children, className, ...props }, ref) => {
  return (
    <motion.button
      ref={ref}
      {...props}
      className={cn(
        "group relative flex h-14 w-full items-center justify-center gap-2 overflow-hidden rounded-2xl bg-primary px-6 py-3 font-semibold text-primary-foreground shadow-[var(--shadow-elevation)] transition-[box-shadow,background-color] duration-150 ease-out hover:bg-primary/90 hover:shadow-[var(--shadow-elevation-hover)]",
        className
      )}
      transition={{ type: "spring", duration: 0.3, bounce: 0 }}
      whileTap={{ scale: 0.96 }}
    >
      <span className="relative z-10">{children}</span>
      <div className="pointer-events-none absolute inset-0 z-0 flex h-full w-full justify-center opacity-0 transition-opacity duration-300 [transform:skew(-12deg)_translateX(-100%)] group-hover:opacity-100 group-hover:duration-1000 group-hover:[transform:skew(-12deg)_translateX(100%)]">
        <div className="relative h-full w-8 bg-white/15" />
      </div>
    </motion.button>
  );
});
ShinyButton.displayName = "ShinyButton";
