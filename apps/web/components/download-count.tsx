"use client";

import { useEffect, useState } from "react";

export function DownloadCount() {
  const [label, setLabel] = useState("—");

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
        setLabel("—");
      });

    return () => controller.abort();
  }, []);

  return <span aria-live="polite">{label}</span>;
}
