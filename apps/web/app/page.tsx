"use client";

import { useState } from "react";

type DemoState = "listening" | "aside";

export default function HomePage() {
  const [state, setState] = useState<DemoState>("listening");
  const listening = state === "listening";

  return (
    <main className="site-shell">
      <nav className="site-nav" aria-label="Main navigation">
        <a className="wordmark" href="#" aria-label="Hear Me Not home">
          hear me not<span className="wordmark-dot">.</span>
        </a>
        <a className="nav-link" href="https://github.com/akashp1712/hearmenot" target="_blank" rel="noreferrer">
          GitHub <span aria-hidden="true">↗</span>
        </a>
      </nav>

      <section className="hero" aria-labelledby="hero-title">
        <p className="eyebrow"><span className="signal" /> Built for Mac</p>
        <h1 id="hero-title">Your Mac doesn’t need<br />to hear everything.</h1>
        <p className="hero-copy">
          Hear Me Not uses AirPods head tracking to keep the words meant for people
          out of your voice apps.
        </p>
        <div className="hero-actions">
          <a className="button button-primary" href="#how-it-works">See how it works</a>
          <span className="quiet-note">Private prototype · macOS</span>
        </div>
      </section>

      <section className="demo-section" aria-label="Interactive product demonstration">
        <div className="demo-label"><span>01</span> A small boundary</div>
        <div className={"demo-card " + (listening ? "is-listening" : "is-aside")}>
          <div className="demo-topline">
            <span className="demo-app">Voice input</span>
            <span className="demo-state" aria-live="polite"><i /> {listening ? "Listening" : "Not for your Mac"}</span>
          </div>
          <div className="demo-body">
            <div className="head-scene" aria-hidden="true">
              <div className="direction direction-left">person</div>
              <div className="head" />
              <div className="direction direction-right">Mac</div>
              <div className="head-caption">{listening ? "Facing your Mac" : "Turned aside"}</div>
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
            <button type="button" onClick={() => setState(listening ? "aside" : "listening")} aria-pressed={!listening}>
              {listening ? "Turn aside →" : "Face Mac again →"}
            </button>
          </div>
        </div>
      </section>

      <section id="how-it-works" className="principle">
        <p className="eyebrow">The missing layer</p>
        <p className="principle-copy">
          Better microphones make speech clearer. Hear Me Not protects the moment
          when your attention is somewhere else.
        </p>
        <div className="steps">
          <div><span>01</span><p>Face your Mac.<br />It listens.</p></div>
          <div><span>02</span><p>Turn toward someone.<br />It stops.</p></div>
          <div><span>03</span><p>Face back.<br />Continue naturally.</p></div>
        </div>
      </section>

      <footer>
        <span>Head-aware microphone privacy for macOS.</span>
        <span>No audio stored. No transcription. Just a boundary.</span>
      </footer>
    </main>
  );
}
