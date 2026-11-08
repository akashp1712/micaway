"use client";

import Image from "next/image";
import { useEffect, useRef, useState } from "react";

const FACING = "/images/turn/00.jpg";
const AWAY = "/images/turn/04.jpg";
const MAX_YAW = 42;

function easeInOut(t: number) {
  return (1 - Math.cos(Math.PI * t)) / 2;
}

function clamp(value: number) {
  return Math.min(1, Math.max(0, value));
}

export function AttentionDemo() {
  const [progress, setProgress] = useState(0);
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

  const stopAnimation = () => {
    cancelAnimationFrame(animateRef.current);
  };

  const animateTo = (target: number) => {
    stopAnimation();
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
      updateProgress(target);
      return;
    }
    const start = progressRef.current;
    const duration = Math.max(180, 680 * Math.abs(target - start));
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
    return () => cancelAnimationFrame(animateRef.current);
  }, []);

  const listening = progress < 0.46;
  const yaw = Math.round(progress * MAX_YAW);

  return (
    <section
      aria-label="Head-direction demonstration"
      className={`attention-demo ${listening ? "is-listening" : "is-aside"}`}
    >
      <div
        aria-describedby="demo-hint"
        aria-label="Turn the head"
        aria-valuemax={MAX_YAW}
        aria-valuemin={0}
        aria-valuenow={yaw}
        aria-valuetext={
          listening
            ? "Facing the Mac, microphone live"
            : `Looked away, microphone muted, ${yaw} degrees`
        }
        className="scene"
        onKeyDown={(event) => {
          if (event.key === " ") {
            event.preventDefault();
            animateTo(progressRef.current < 0.46 ? 1 : 0);
          }
          if (event.key === "ArrowRight" || event.key === "End") {
            event.preventDefault();
            animateTo(1);
          }
          if (event.key === "ArrowLeft" || event.key === "Home") {
            event.preventDefault();
            animateTo(0);
          }
        }}
        onLostPointerCapture={() => {
          dragRef.current = null;
        }}
        onPointerCancel={() => {
          dragRef.current = null;
        }}
        onPointerDown={(event) => {
          if (!event.isPrimary || event.button !== 0) {
            return;
          }
          stopAnimation();
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
            animateTo(progressRef.current < 0.46 ? 1 : 0);
          } else if (drag) {
            animateTo(progressRef.current < 0.46 ? 0 : 1);
          }
        }}
        ref={sceneRef}
        role="slider"
        tabIndex={0}
      >
        {/* Keep an opaque base so the dissolve never exposes the scene background. */}
        <div className="scene-photo">
          <Image
            alt="A developer facing a Mac while wearing AirPods"
            fill
            priority
            sizes="(max-width: 640px) calc(100vw - 40px), (max-width: 848px) calc(100vw - 48px), 800px"
            src={FACING}
          />
        </div>
        <div className="scene-photo" style={{ opacity: progress }}>
          <Image
            alt="The same developer turning away from the Mac to speak"
            fill
            priority
            sizes="(max-width: 640px) calc(100vw - 40px), (max-width: 848px) calc(100vw - 48px), 800px"
            src={AWAY}
          />
        </div>
        <div aria-hidden="true" className="scene-menu">
          <Image
            alt=""
            className={listening ? "is-shown" : undefined}
            height={321}
            src="/images/menu/listening.png"
            width={356}
          />
          <Image
            alt=""
            className={listening ? undefined : "is-shown"}
            height={321}
            src="/images/menu/away.png"
            width={356}
          />
        </div>
      </div>

      <p aria-atomic="true" aria-live="polite" className="attention-status">
        <strong>
          <i aria-hidden="true" />
          {listening ? "Facing the Mac — mic live" : "Looking away — mic muted"}
        </strong>
        <span>
          {listening
            ? "Your call can hear you."
            : "Your aside stays out of the call."}
        </span>
      </p>

      <p className="demo-hint" id="demo-hint">
        Drag the photo or choose a position. Arrow keys work too.
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
