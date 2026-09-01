"use client";

import Image from "next/image";
import { useEffect, useRef, useState } from "react";

const FACING = "/images/turn/00.jpg";
const AWAY = "/images/turn/04.jpg";
const MAX_YAW = 42;

function easeInOut(t: number) {
  return t < 0.5 ? 4 * t * t * t : 1 - (-2 * t + 2) ** 3 / 2;
}

function clamp(value: number) {
  return Math.min(1, Math.max(0, value));
}

type TurnPhase = "hold-face" | "turn-away" | "hold-away" | "turn-face";

function playTurnLoop(
  getProgress: () => number,
  setProgressValue: (value: number) => void,
  isActive: () => boolean
) {
  const holdMs = 1800;
  const turnMs = 2200;
  let raf = 0;
  let phase: TurnPhase = "hold-face";
  let phaseStart = performance.now();
  let from = 0;

  const tick = (now: number) => {
    if (!isActive()) {
      return;
    }

    const elapsed = now - phaseStart;

    if (phase === "hold-face" && elapsed >= holdMs) {
      phase = "turn-away";
      phaseStart = now;
      from = getProgress();
    } else if (phase === "turn-away") {
      const t = Math.min(1, elapsed / turnMs);
      setProgressValue(from + (1 - from) * easeInOut(t));
      if (t >= 1) {
        phase = "hold-away";
        phaseStart = now;
      }
    } else if (phase === "hold-away" && elapsed >= holdMs) {
      phase = "turn-face";
      phaseStart = now;
      from = getProgress();
    } else if (phase === "turn-face") {
      const t = Math.min(1, elapsed / turnMs);
      setProgressValue(from * (1 - easeInOut(t)));
      if (t >= 1) {
        phase = "hold-face";
        phaseStart = now;
      }
    }

    raf = requestAnimationFrame(tick);
  };

  raf = requestAnimationFrame(tick);
  return () => cancelAnimationFrame(raf);
}

export function AttentionDemo() {
  const [progress, setProgress] = useState(0);
  const autoPlayRef = useRef(true);
  const [autoPlay, setAutoPlay] = useState(true);
  const progressRef = useRef(0);
  const sceneRef = useRef<HTMLDivElement>(null);
  const animateRef = useRef(0);
  const dragRef = useRef<{
    startX: number;
    startProgress: number;
    moved: boolean;
  } | null>(null);

  const updateProgress = (value: number) => {
    const next = clamp(value);
    progressRef.current = next;
    setProgress(next);
  };

  const stopAuto = () => {
    autoPlayRef.current = false;
    setAutoPlay(false);
    cancelAnimationFrame(animateRef.current);
  };

  const animateTo = (target: number, duration = 2000) => {
    stopAuto();
    const start = progressRef.current;
    const started = performance.now();

    const tick = (now: number) => {
      const t = Math.min(1, (now - started) / duration);
      updateProgress(start + (target - start) * easeInOut(t));
      if (t < 1) {
        animateRef.current = requestAnimationFrame(tick);
      }
    };

    animateRef.current = requestAnimationFrame(tick);
  };

  useEffect(() => {
    for (const src of [FACING, AWAY]) {
      const image = new window.Image();
      image.src = src;
    }
  }, []);

  useEffect(() => {
    if (
      !autoPlay ||
      window.matchMedia("(prefers-reduced-motion: reduce)").matches
    ) {
      return;
    }

    return playTurnLoop(
      () => progressRef.current,
      (value) => {
        const next = clamp(value);
        progressRef.current = next;
        setProgress(next);
      },
      () => autoPlayRef.current
    );
  }, [autoPlay]);

  useEffect(() => {
    return () => cancelAnimationFrame(animateRef.current);
  }, []);

  const listening = progress < 0.46;
  const yaw = Math.round(progress * MAX_YAW);
  const blur = Math.sin(progress * Math.PI) * 1.4;

  return (
    <section
      aria-label="Head-direction demonstration"
      className={`attention-demo ${listening ? "is-listening" : "is-aside"}`}
    >
      <div
        aria-label="Turn the head"
        aria-valuemax={MAX_YAW}
        aria-valuemin={0}
        aria-valuenow={yaw}
        aria-valuetext={
          listening ? "Facing the Mac" : `Looked away, ${yaw} degrees`
        }
        className="scene"
        onKeyDown={(event) => {
          if (event.key === "ArrowRight" || event.key === " ") {
            event.preventDefault();
            animateTo(1);
          }
          if (event.key === "ArrowLeft") {
            event.preventDefault();
            animateTo(0);
          }
        }}
        onPointerDown={(event) => {
          stopAuto();
          event.currentTarget.setPointerCapture(event.pointerId);
          dragRef.current = {
            startX: event.clientX,
            startProgress: progressRef.current,
            moved: false,
          };
        }}
        onPointerMove={(event) => {
          const drag = dragRef.current;
          if (!drag) {
            return;
          }

          const width = sceneRef.current?.clientWidth ?? 800;
          const delta = event.clientX - drag.startX;
          if (Math.abs(delta) > 6) {
            drag.moved = true;
          }
          updateProgress(drag.startProgress + delta / (width * 0.58));
        }}
        onPointerUp={() => {
          const drag = dragRef.current;
          dragRef.current = null;
          if (drag && !drag.moved) {
            animateTo(progressRef.current < 0.5 ? 1 : 0);
          }
        }}
        ref={sceneRef}
        role="slider"
        tabIndex={0}
      >
        <div
          className="scene-photo"
          style={{
            opacity: 1 - progress,
            filter: `blur(${blur}px)`,
            transform: `scale(${1 + progress * 0.035}) translateX(${progress * -10}px)`,
            zIndex: progress < 1 ? 1 : 0,
          }}
        >
          <Image
            alt="A developer facing a Mac while wearing AirPods"
            fill
            priority
            sizes="(max-width: 920px) calc(100vw - 48px), 860px"
            src={FACING}
          />
        </div>
        <div
          className="scene-photo"
          style={{
            opacity: progress,
            filter: `blur(${blur}px)`,
            transform: `scale(${1.035 - progress * 0.035}) translateX(${(1 - progress) * 10}px)`,
            zIndex: progress > 0 ? 1 : 0,
          }}
        >
          <Image
            alt="The same developer turning away from the Mac to speak"
            fill
            priority
            sizes="(max-width: 920px) calc(100vw - 48px), 860px"
            src={AWAY}
          />
        </div>
        <div className="scene-card">
          <span>
            <i className={listening ? "is-live" : undefined} /> MicAway
            <code>{yaw}°</code>
          </span>
          <strong>{listening ? "Listening" : "Not for your Mac"}</strong>
          <small>
            {listening
              ? "The prompt reaches the agent."
              : "The aside stays between you two."}
          </small>
        </div>
      </div>

      <p className="attention-status">
        <strong>{listening ? "Facing the Mac" : "Looked away"}</strong>
        <span>
          {listening
            ? "Voice stays in the session. Drag or click the photo to turn."
            : "Someone beside you asked a question."}
        </span>
      </p>

      <div className="attention-toggle">
        <button
          aria-pressed={listening}
          onClick={() => animateTo(0)}
          type="button"
        >
          Face the Mac
        </button>
        <button
          aria-pressed={!listening}
          onClick={() => animateTo(1)}
          type="button"
        >
          Look away
        </button>
      </div>
    </section>
  );
}
