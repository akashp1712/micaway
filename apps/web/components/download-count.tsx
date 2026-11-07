"use client";

import { useEffect, useState } from "react";

/** Total release downloads from GitHub. Renders nothing until the count loads
 * or if it is unavailable, so the page never shows a placeholder number. */
export function DownloadCount({ prefix = "" }: { prefix?: string }) {
  const [label, setLabel] = useState<string | null>(null);

  useEffect(() => {
    const controller = new AbortController();

    fetch("/api/downloads", { signal: controller.signal })
      .then((response) => {
        if (!response.ok) {
          throw new Error("Download count unavailable");
        }
        return response.json() as Promise<{ downloads: number }>;
      })
      .then(({ downloads }) => {
        setLabel(
          new Intl.NumberFormat("en", { notation: "compact" }).format(downloads)
        );
      })
      .catch((error: unknown) => {
        if (error instanceof DOMException && error.name === "AbortError") {
          return;
        }
        setLabel(null);
      });

    return () => controller.abort();
  }, []);

  return (
    <span aria-live="polite">
      {label === null ? null : `${prefix}${label} downloads`}
    </span>
  );
}
