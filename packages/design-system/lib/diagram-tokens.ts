/**
 * Diagram kit tokens — CSS vars for in-app React SVG;
 * hex fallbacks for static SVG export (LinkedIn / X / email).
 */

export type DiagramVariant = "idle" | "active" | "held" | "warn";

/** Light-canvas hex fallbacks (warm kit hospitality look). */
export const diagramFallbackLight = {
  ink: "#2E2820",
  muted: "#6B6358",
  surface: "#FFFFFF",
  canvas: "#FAF9F6",
  border: "#E4E0D8",
  edge: "#8A8278",
  label: "#2E2820",
  mono: "#6B6358",
  accentHeld: "#2F7A5E",
  accentActive: "#2E2820",
  accentWarn: "#B33A2B",
  nodeIdle: "#F1EEE8",
  nodeFill: "#FFFFFF",
} as const;

/** Dark-canvas hex fallbacks. */
export const diagramFallbackDark = {
  ink: "#F7F5F1",
  muted: "#B0A89E",
  surface: "#2A2622",
  canvas: "#1F1C19",
  border: "#3D3832",
  edge: "#9A9288",
  label: "#F7F5F1",
  mono: "#B0A89E",
  accentHeld: "#4BA88A",
  accentActive: "#F7F5F1",
  accentWarn: "#E07060",
  nodeIdle: "#35302B",
  nodeFill: "#2A2622",
} as const;

export type DiagramFallbackPalette = typeof diagramFallbackLight;

export const diagramCssVars = {
  ink: "var(--diagram-ink)",
  muted: "var(--diagram-muted)",
  surface: "var(--diagram-surface)",
  canvas: "var(--diagram-canvas)",
  border: "var(--diagram-border)",
  edge: "var(--diagram-edge)",
  label: "var(--diagram-label)",
  mono: "var(--diagram-mono)",
  accentHeld: "var(--diagram-accent-held)",
  accentActive: "var(--diagram-accent-active)",
  accentWarn: "var(--diagram-accent-warn)",
  nodeIdle: "var(--diagram-node-idle)",
  nodeFill: "var(--diagram-node-fill)",
  radius: "var(--diagram-radius)",
} as const;

export function getDiagramPalette(
  mode: "css" | "light" | "dark" = "css"
): Record<keyof typeof diagramCssVars, string> {
  if (mode === "light") {
    return {
      ...diagramFallbackLight,
      radius: "12px",
    };
  }
  if (mode === "dark") {
    return {
      ...diagramFallbackDark,
      radius: "12px",
    };
  }
  return { ...diagramCssVars };
}

export function variantColors(
  variant: DiagramVariant,
  palette: ReturnType<typeof getDiagramPalette>
) {
  switch (variant) {
    case "held":
      return {
        fill: palette.nodeFill,
        stroke: palette.accentHeld,
        title: palette.ink,
        subtitle: palette.muted,
        accent: palette.accentHeld,
      };
    case "active":
      return {
        fill: palette.nodeFill,
        stroke: palette.accentActive,
        title: palette.ink,
        subtitle: palette.muted,
        accent: palette.accentActive,
      };
    case "warn":
      return {
        fill: palette.nodeFill,
        stroke: palette.accentWarn,
        title: palette.ink,
        subtitle: palette.muted,
        accent: palette.accentWarn,
      };
    default:
      return {
        fill: palette.nodeIdle,
        stroke: palette.border,
        title: palette.ink,
        subtitle: palette.muted,
        accent: palette.edge,
      };
  }
}

/** Capture mark path (viewBox 0 0 32 32) — use sparingly on held nodes. */
export const CAPTURE_MARK_PATH =
  "M10 4h12a6 6 0 0 1 6 6v4.2a2 2 0 0 1-1.2 1.83l-5.1 2.22a2 2 0 0 0-1.2 1.83V22a6 6 0 0 1-6 6H10a6 6 0 0 1-6-6V10a6 6 0 0 1 6-6z";
