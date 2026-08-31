import { cn } from "@repo/design-system/lib/utils";
import type React from "react";

export const BentoGrid = ({
  className,
  children,
}: {
  className?: string;
  children?: React.ReactNode;
}) => {
  return (
    <div
      className={cn(
        "mx-auto grid w-full grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3 lg:items-stretch",
        className
      )}
    >
      {children}
    </div>
  );
};

export const BentoGridItem = ({
  className,
  title,
  description,
  header,
  icon,
}: {
  className?: string;
  title?: string | React.ReactNode;
  description?: string | React.ReactNode;
  header?: React.ReactNode;
  icon?: React.ReactNode;
}) => {
  return (
    <div
      className={cn(
        "group/bento relative flex h-full flex-col gap-4 rounded-3xl bg-card p-5 shadow-[var(--shadow-elevation)] transition-[box-shadow,transform] duration-200 ease-out hover:-translate-y-0.5 hover:shadow-[var(--shadow-elevation-hover)] sm:gap-5 sm:p-6",
        className
      )}
    >
      {header}
      <div className="z-10 flex flex-1 flex-col">
        <div className="mb-3 flex min-h-[3.25rem] items-start gap-2 sm:min-h-[3.5rem]">
          <div className="mt-0.5 shrink-0 text-foreground/80">{icon}</div>
          <div className="font-semibold text-base text-foreground leading-snug tracking-tight sm:text-lg">
            {title}
          </div>
        </div>
        <div className="font-normal text-foreground/80 text-sm leading-relaxed sm:text-base">
          {description}
        </div>
      </div>
    </div>
  );
};
