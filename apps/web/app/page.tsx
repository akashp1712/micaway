"use client";

import { useState } from "react";
import Image from "next/image";
import {
  Check,
  Download,
  Github,
  Mic2,
  MicOff,
  ShieldCheck,
} from "lucide-react";

type DemoState = "listening" | "aside";

const githubUrl = "https://github.com/akashp1712/micaway";
const releaseUrl = `${githubUrl}/releases/latest`;

const voiceApps = [
  {
    name: "Wispr Flow",
    logo: "/brands/wispr-flow.png",
    logoClass: "wispr-logo",
    copy: "Turn to answer someone nearby without sending the aside into your dictation.",
    status: "Community test wanted",
    verified: false,
  },
  {
    name: "FluidVoice",
    logo: "/brands/fluidvoice.png",
    logoClass: "fluidvoice-logo",
    copy: "Keep local, private dictation focused when the room around you gets conversational.",
    status: "Manually verified",
    verified: true,
  },
  {
    name: "ChatGPT Voice",
    logo: "/brands/chatgpt.webp",
    logoClass: "chatgpt-logo",
    copy: "Use a natural head turn to pause your microphone during a voice conversation.",
    status: "Community test wanted",
    verified: false,
  },
] as const;

export default function HomePage() {
  const [state, setState] = useState<DemoState>("listening");
  const listening = state === "listening";

  return (
    <main className="site-shell">
      <nav className="site-nav" aria-label="Main navigation">
        <a className="wordmark" href="#" aria-label="MicAway home">
          <Image
            className="wordmark-icon"
            src="/brand/micaway-mark.svg"
            alt=""
            width={22}
            height={22}
          />
          MicAway
        </a>
        <div className="nav-actions">
          <a
            className="nav-link"
            href={githubUrl}
            target="_blank"
            rel="noreferrer"
          >
            GitHub <span aria-hidden="true">↗</span>
          </a>
          <a
            className="nav-download"
            href={releaseUrl}
            target="_blank"
            rel="noreferrer"
          >
            Download
          </a>
        </div>
      </nav>

      <section className="hero" aria-labelledby="hero-title">
        <p className="eyebrow">
          <span className="signal" /> Open source · macOS
        </p>
        <h1 id="hero-title">
          Turn your head.
          <br />
          <em>Mute the mic.</em>
        </h1>
        <p className="hero-copy">
          MicAway uses AirPods head tracking to keep side conversations out of
          voice dictation. Face your Mac to speak. Turn away for privacy.
        </p>
        <div className="hero-actions">
          <a
            className="button button-primary"
            href={releaseUrl}
            target="_blank"
            rel="noreferrer"
          >
            <Download aria-hidden="true" /> Download preview
          </a>
          <a
            className="text-link"
            href={githubUrl}
            target="_blank"
            rel="noreferrer"
          >
            View source ↗
          </a>
        </div>
        <p className="quiet-note">
          Free · Apple silicon · macOS 14+ · No audio access
        </p>
      </section>

      <section
        id="try-it"
        className={
          "boundary-stage " + (listening ? "is-listening" : "is-aside")
        }
        aria-labelledby="boundary-title"
      >
        <div className="boundary-intro">
          <div>
            <p className="stage-kicker">
              <span /> Live product demo
            </p>
            <h2 id="boundary-title">
              Your attention
              <br />
              is the switch.
            </h2>
          </div>
          <div className="stage-copy">
            <p>Choose a direction. Watch what reaches the voice app.</p>
            <div className="boundary-switch" aria-label="Head direction">
              <button
                type="button"
                onClick={() => setState("listening")}
                aria-pressed={listening}
              >
                Facing Mac
              </button>
              <button
                type="button"
                onClick={() => setState("aside")}
                aria-pressed={!listening}
              >
                Turned away
              </button>
            </div>
          </div>
        </div>

        <div className="macbook-demo">
          <Image
            className="macbook-frame"
            src="/images/macbook-frame.png"
            alt="MacBook showing the MicAway head-aware microphone boundary"
            width={3944}
            height={2564}
            unoptimized
            sizes="(max-width: 700px) 120vw, 1200px"
          />
          <div className="macbook-screen">
            <div className="screen-grid" aria-hidden="true" />
            <div className="screen-glow" aria-hidden="true" />
            <div className="screen-topline">
              <span className="screen-brand">
                <i /> MicAway
              </span>
              <span className="screen-status" aria-live="polite">
                {listening ? (
                  <Mic2 aria-hidden="true" />
                ) : (
                  <MicOff aria-hidden="true" />
                )}
                {listening ? "Mic live" : "Mic muted"}
              </span>
            </div>

            <div className="intent-label intent-person">Someone nearby</div>
            <div className="intent-label intent-mac">Your Mac</div>
            <div className="tracking-orbit orbit-one" aria-hidden="true" />
            <div className="tracking-orbit orbit-two" aria-hidden="true" />
            <Image
              className="tracking-portrait"
              src="/images/micaway-tracking-portrait-v2.png"
              alt="Person wearing AirPods with subtle head-tracking lines"
              width={1536}
              height={1024}
              unoptimized
            />

            <div className="voice-card captured-card">
              <span>Voice app</span>
              <p>“Turn this into a clearer launch plan.”</p>
              <div className="waveform" aria-hidden="true">
                <i />
                <i />
                <i />
                <i />
                <i />
                <i />
                <i />
              </div>
            </div>

            <div className="voice-card private-card">
              <span>
                <ShieldCheck aria-hidden="true" /> Side conversation
              </span>
              <p>“Yes, I’ll be there in five.”</p>
              <strong>Not captured</strong>
            </div>

            <div className="direction-readout">
              <span>{listening ? "0°" : "42°"}</span>
              <p>{listening ? "Facing your Mac" : "Intent moved away"}</p>
            </div>
          </div>
        </div>
        <p className="stage-caption">
          No wake word. No shortcut. Your head movement is enough.
        </p>
      </section>

      <section className="compatibility" aria-labelledby="compatibility-title">
        <div className="compatibility-heading">
          <div>
            <p className="eyebrow">
              <span className="signal" /> One gesture, across voice apps
            </p>
            <h2 id="compatibility-title">
              Keep the thought.
              <br />
              <em>Lose the aside.</em>
            </h2>
          </div>
          <p>
            MicAway works at the input-device level, so your head turn can
            protect the voice workflow already on your Mac.
          </p>
        </div>

        <div className="compatibility-rail">
          <div className="rail-line" aria-hidden="true">
            <i />
          </div>
          {voiceApps.map((app, index) => (
            <article
              className="voice-app"
              key={app.name}
              style={{ "--delay": `${index * 1.2}s` } as React.CSSProperties}
            >
              <div className="voice-app-topline">
                <span className={`voice-app-logo ${app.logoClass}`}>
                  <Image
                    src={app.logo}
                    alt={`${app.name} logo`}
                    width={64}
                    height={64}
                    unoptimized
                  />
                </span>
                <span className="plus" aria-hidden="true">
                  +
                </span>
                <span className="mini-micaway">
                  <Image
                    src="/brand/micaway-mark.svg"
                    alt="MicAway"
                    width={34}
                    height={34}
                  />
                </span>
              </div>
              <h3>
                {app.name} <span>+ MicAway</span>
              </h3>
              <p>{app.copy}</p>
              <div
                className={`compatibility-status ${app.verified ? "is-verified" : ""}`}
              >
                {app.verified ? (
                  <Check aria-hidden="true" />
                ) : (
                  <i aria-hidden="true" />
                )}
                {app.status}
              </div>
            </article>
          ))}
        </div>
        <p className="trademark-note">
          MicAway is independent and is not affiliated with or endorsed by Wispr
          Flow, FluidVoice, or OpenAI. Names and logos belong to their
          respective owners.
        </p>
      </section>

      <section className="principle">
        <p className="eyebrow">
          <span className="signal" /> How it works
        </p>
        <p className="principle-copy">
          Your attention becomes the mute button.
        </p>
        <div className="steps">
          <div>
            <span>01</span>
            <p>
              Calibrate once
              <br />
              while facing forward.
            </p>
          </div>
          <div>
            <span>02</span>
            <p>
              Turn away.
              <br />
              Your mics mute.
            </p>
          </div>
          <div>
            <span>03</span>
            <p>
              Face back.
              <br />
              Keep dictating.
            </p>
          </div>
        </div>
      </section>

      <section className="open-source" aria-labelledby="open-source-title">
        <p className="eyebrow">
          <span className="signal" /> Built in the open
        </p>
        <h2 id="open-source-title">
          Small utility.
          <br />
          Clear promise.
        </h2>
        <div className="open-source-copy">
          <p>
            MicAway reads head direction—not audio. It records nothing, stores
            nothing, and sends nothing to a server.
          </p>
          <a
            className="button button-primary"
            href={githubUrl}
            target="_blank"
            rel="noreferrer"
          >
            <Github aria-hidden="true" /> Read the code
          </a>
        </div>
      </section>

      <section className="install" aria-labelledby="install-title">
        <div>
          <p className="eyebrow">
            <span className="signal" /> Developer preview
          </p>
          <h2 id="install-title">
            Try it free.
            <br />
            Build it with us.
          </h2>
        </div>
        <div className="install-card">
          <ol>
            <li>
              <span>1</span>
              <p>
                <strong>Download</strong> the latest Apple-silicon build from
                GitHub Releases.
              </p>
            </li>
            <li>
              <span>2</span>
              <p>
                <strong>Open MicAway</strong> and approve it in Privacy &amp;
                Security if macOS asks.
              </p>
            </li>
            <li>
              <span>3</span>
              <p>
                <strong>Wear your AirPods</strong>, face forward, and calibrate
                once.
              </p>
            </li>
          </ol>
          <a
            className="button button-light"
            href={releaseUrl}
            target="_blank"
            rel="noreferrer"
          >
            <Download aria-hidden="true" /> Get MicAway 0.1
          </a>
          <p className="preview-note">
            Unsigned open-source preview · Full source and checksums included
          </p>
        </div>
      </section>

      <footer>
        <span>MicAway · Free and MIT licensed</span>
        <span>Built by Akash Panchal for people who think out loud.</span>
      </footer>
    </main>
  );
}
