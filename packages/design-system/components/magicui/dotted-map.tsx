import { cn } from "@repo/design-system/lib/utils";
import * as React from "react";
import { createMap } from "svg-dotted-map";

export interface Marker {
  lat: number;
  lng: number;
  pulse?: boolean;
  size?: number;
}

type MapMarker<M extends Marker> = Omit<M, "lat" | "lng"> & {
  x: number;
  y: number;
};

type Region = {
  lat: { min: number; max: number };
  lng: { min: number; max: number };
};

export interface DottedMapProps<M extends Marker = Marker>
  extends React.SVGProps<SVGSVGElement> {
  countries?: string[];
  dotColor?: string;
  dotRadius?: number;
  height?: number;
  mapSamples?: number;
  markerColor?: string;
  markers?: M[];
  pulse?: boolean;
  region?: Region;
  renderMarkerOverlay?: (args: {
    marker: MapMarker<M>;
    index: number;
    x: number;
    y: number;
    r: number;
  }) => React.ReactNode;
  stagger?: boolean;
  /** Extra dots in SVG space (e.g. Tasmania — missing from bundled AUS polygon). */
  supplementaryPoints?: { x: number; y: number }[];
  width?: number;
}

export function DottedMap<M extends Marker = Marker>({
  width = 150,
  height = 75,
  mapSamples = 5000,
  countries,
  region,
  markers = [],
  dotColor = "currentColor",
  markerColor = "#FF6900",
  dotRadius = 0.2,
  stagger = true,
  pulse = false,
  renderMarkerOverlay,
  supplementaryPoints = [],
  className,
  style,
  ...svgProps
}: DottedMapProps<M>) {
  const { points, addMarkers } = createMap({
    width,
    height,
    mapSamples,
    countries,
    region,
  });
  const processedMarkers = addMarkers(markers);

  const { xStep, yToRowIndex } = React.useMemo(() => {
    const sorted = [...points].sort((a, b) => a.y - b.y || a.x - b.x);
    const rowMap = new Map<number, number>();
    let step = 0;
    let prevY = Number.NaN;
    let prevXInRow = Number.NaN;

    for (const p of sorted) {
      if (p.y !== prevY) {
        prevY = p.y;
        prevXInRow = Number.NaN;
        if (!rowMap.has(p.y)) {
          rowMap.set(p.y, rowMap.size);
        }
      }
      if (!Number.isNaN(prevXInRow)) {
        const delta = p.x - prevXInRow;
        if (delta > 0) {
          step = step === 0 ? delta : Math.min(step, delta);
        }
      }
      prevXInRow = p.x;
    }

    return { xStep: step || 1, yToRowIndex: rowMap };
  }, [points]);

  return (
    <svg
      aria-hidden
      className={cn("text-muted-foreground/35", className)}
      style={{ width: "100%", height: "100%", ...style }}
      viewBox={`0 0 ${width} ${height}`}
      {...svgProps}
    >
      {points.map((point, index) => {
        const rowIndex = yToRowIndex.get(point.y) ?? 0;
        const offsetX = stagger && rowIndex % 2 === 1 ? xStep / 2 : 0;
        return (
          <circle
            cx={point.x + offsetX}
            cy={point.y}
            fill={dotColor}
            key={`${point.x}-${point.y}-${index}`}
            r={dotRadius}
          />
        );
      })}

      {supplementaryPoints.map((point, index) => {
        const rowIndex = yToRowIndex.get(point.y) ?? 0;
        const offsetX = stagger && rowIndex % 2 === 1 ? xStep / 2 : 0;
        return (
          <circle
            cx={point.x + offsetX}
            cy={point.y}
            fill={dotColor}
            key={`supp-${point.x}-${point.y}-${index}`}
            r={dotRadius}
          />
        );
      })}

      {processedMarkers.map((marker, index) => {
        const rowIndex = yToRowIndex.get(marker.y) ?? 0;
        const offsetX = stagger && rowIndex % 2 === 1 ? xStep / 2 : 0;

        const x = marker.x + offsetX;
        const y = marker.y;
        const r = marker.size ?? dotRadius;
        const shouldPulse = pulse
          ? marker.pulse !== false
          : marker.pulse === true;
        const pulseTo = r * 2.8;

        return (
          <g key={`${marker.x}-${marker.y}-${index}`}>
            <circle cx={x} cy={y} fill={markerColor} r={r} />

            {shouldPulse ? (
              <g pointerEvents="none">
                <circle
                  cx={x}
                  cy={y}
                  fill="none"
                  r={r}
                  stroke={markerColor}
                  strokeOpacity={1}
                  strokeWidth={0.35}
                >
                  <animate
                    attributeName="r"
                    dur="1.4s"
                    repeatCount="indefinite"
                    values={`${r};${pulseTo}`}
                  />
                  <animate
                    attributeName="opacity"
                    dur="1.4s"
                    repeatCount="indefinite"
                    values="1;0"
                  />
                </circle>
                <circle
                  cx={x}
                  cy={y}
                  fill="none"
                  r={r}
                  stroke={markerColor}
                  strokeOpacity={0.9}
                  strokeWidth={0.3}
                >
                  <animate
                    attributeName="r"
                    begin="0.7s"
                    dur="1.4s"
                    repeatCount="indefinite"
                    values={`${r};${pulseTo}`}
                  />
                  <animate
                    attributeName="opacity"
                    begin="0.7s"
                    dur="1.4s"
                    repeatCount="indefinite"
                    values="0.9;0"
                  />
                </circle>
              </g>
            ) : null}

            {renderMarkerOverlay?.({
              marker: { ...marker, x, y },
              index,
              x,
              y,
              r,
            })}
          </g>
        );
      })}
    </svg>
  );
}
