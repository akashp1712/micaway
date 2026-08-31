"use client";

import { useState } from "react";

type DemoState = "listening" | "away";

export default function HomePage() {
  const [state, setState] = useState<DemoState>("listening");
  const listening = state === "listening";

  return (
    <main className="site-shell">
      <nav className="site-nav" aria-label="Main navigation">
        <a className="wordmark" href="#" aria-label="MicAway home">
          micaway<span className="wordmark-dot">.</span>
        </a>
        <a
          className="nav-link"
          href="https://github.com/akashp1712/micaway"
          target="_blank"
          rel="noreferrer"
        >
          GitHub <span aria-hidden="true">↗</span>
        </a>
      </nav>

      <section className="hero" aria-labelledby="hero-title">
        <p className="eyebrow"><span className="signal" /> Built for Mac</p>
        <h1 id="hero-title">Look away.<br />Mic away.</h1>
        <p className="hero-copy">
          MicAway uses AirPods head tracking to keep side conversations out of
          ChatGPT, Claude, Cursor, and every voice app.
        </p>
        <div className="hero-actions">
          <a className="button button-primary" href="#how-it-works">See it work</a>
          <span className="quiet-note">Private prototype · macOS</span>
        </div>
      </section>

      <section className="demo-section" aria-label="Interactive MicAway demonstration">
        <div className="demo-label"><span>01</span> Your mic follows your attention</div>
        <div className={"demo-card " + (listening ? "is-listening" : "is-aside")}>
          <div className="demo-topline">
            <span className="demo-app">MicAway</span>
            <span className="demo-state" aria-live="polite">
              <i /> {listening ? "Listening" : "Mic away"}
            </span>
          </div>
          <div className="demo-body">
            <div className="head-scene" aria-hidden="true">
              <div className="direction direction-left">person</div>
              <div className="head" />
              <div className="direction direction-right">Mac</div>
              <div className="head-caption">
                {listening ? "Facing your Mac" : "Looking away"}
              </div>
            </div>
            <div className="transcript">
              <p className="transcript-label">What gets captured</p>
              <p className="captured">“Can you turn this into a clearer launch plan?”</p>
              <p className={"excluded " + (listening ? "" : "visible")}>
                “Dinner is on the table.” <span>— not captured</span>
              </p>
            </div>
          </div>
          <div className="demo-control">
            <p>{listening ? "Talking to your Mac" : "Talking to someone else"}</p>
            <button
              type="button"
              onClick={() => setState(listening ? "away" : "listening")}
              aria-pressed={!listening}
            >
              {listening ? "Look away →" : "Face Mac again →"}
            </button>
          </div>
        </div>
      </section>

      <section id="how-it-works" className="principle">
        <p className="eyebrow">The missing layer</p>
        <p className="principle-copy">
          Better microphones hear you clearly. MicAway knows when those words
          were not for your Mac.
        </p>
        <div className="steps">
          <div><span>01</span><p>Face your Mac.<br />It listens.</p></div>
          <div><span>02</span><p>Look away.<br />Mic away.</p></div>
          <div><span>03</span><p>Face back.<br />Continue naturally.</p></div>
        </div>
      </section>

      <footer>
        <span>Attention-aware microphone control for macOS.</span>
        <span>No audio stored. No transcription. Just a boundary.</span>
      </footer>
    </main>
  );
}
