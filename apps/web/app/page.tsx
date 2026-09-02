"use client";

import { useState } from "react";
import Image from "next/image";
import {
  Check,
  Copy,
  Download,
  Github,
  Mic2,
  MicOff,
  ShieldCheck,
} from "lucide-react";

type DemoState = "listening" | "aside";

const githubUrl = "https://github.com/akashp1712/micaway";
const releaseUrl = `${githubUrl}/releases/latest`;
const installCommand = `xattr -cr "/Applications/MicAway.app"
open "/Applications/MicAway.app"`;

const voiceApps = [
  {
    name: "ChatGPT Voice",
    logo: "/brands/chatgpt.webp",
    logoClass: "chatgpt-logo",
    copy: "The voice session stays open. Turn away and the sentence meant for someone beside you stays out.",
    status: "Priority test",
    verified: false,
  },
  {
    name: "Wispr Flow",
    logo: "/brands/wispr-flow.png",
    logoClass: "wispr-logo",
    copy: "Release the dictation key today. Use MicAway when you want a hands-free boundary around your voice workflow.",
    status: "Community test wanted",
    verified: false,
  },
  {
    name: "FluidVoice",
    logo: "/brands/fluidvoice.png",
    logoClass: "fluidvoice-logo",
    copy: "Keep local dictation focused when your room gets conversational—and test the interaction model beyond hotkeys.",
    status: "Manually verified",
    verified: true,
  },
] as const;

export default function HomePage() {
  const [state, setState] = useState<DemoState>("listening");
  const [commandCopied, setCommandCopied] = useState(false);
  const listening = state === "listening";

  const copyInstallCommand = async () => {
    await navigator.clipboard.writeText(installCommand);
    setCommandCopied(true);
    window.setTimeout(() => setCommandCopied(false), 1800);
  };

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
          <span className="signal" /> Open source · Built for continuous voice
        </p>
        <h1 id="hero-title">
          Not every word
          <br />
          <em>is a prompt.</em>
        </h1>
        <p className="hero-copy">
          You&apos;re talking to an AI. Someone beside you asks a question. You
          answer them—and your Mac hears it too. MicAway turns your AirPods into
          the missing boundary for continuous voice.
        </p>
        <div className="hero-actions">
          <a
            className="button button-primary"
            href={releaseUrl}
            target="_blank"
            rel="noreferrer"
          >
            <Download aria-hidden="true" /> Download developer preview
          </a>
          <a
            className="text-link"
            href={githubUrl}
            target="_blank"
            rel="noreferrer"
          >
            Star it on GitHub ↗
          </a>
        </div>
        <p className="quiet-note">
          Look away. Mic away. · macOS 14+ · No microphone permission
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
              The agent stays.
              <br />
              The aside doesn&apos;t.
            </h2>
          </div>
          <div className="stage-copy">
            <p>
              Keep the voice session open. Move your attention and watch what
              reaches the agent.
            </p>
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
                {listening ? "Agent listening" : "Not for your agent"}
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
              <p>“Refactor this handler and add the edge-case tests.”</p>
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
              <p>“Yeah, I’ll join in five.”</p>
              <strong>Not sent to the agent</strong>
            </div>

            <div className="direction-readout">
              <span>{listening ? "0°" : "42°"}</span>
              <p>{listening ? "Talking to your agent" : "Talking to someone else"}</p>
            </div>
          </div>
        </div>
        <p className="stage-caption">
          The voice session stays open. The side conversation stays out.
        </p>
      </section>

      <section className="compatibility" aria-labelledby="compatibility-title">
        <div className="compatibility-heading">
          <div>
            <p className="eyebrow">
              <span className="signal" /> The voice workflow changed
            </p>
            <h2 id="compatibility-title">
              Hotkeys worked.
              <br />
              <em>Then voice stayed open.</em>
            </h2>
          </div>
          <p>
            Dictation ends when you release a key. Continuous voice agents stay
            ready—and have no signal for “I&apos;m talking to the person beside
            me.” MicAway adds one.
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
          A human gesture—not another shortcut to remember.
        </p>
        <div className="steps">
          <div>
            <span>01</span>
            <p>
              Start the voice session.
              <br />
              Keep your hands on the work.
            </p>
          </div>
          <div>
            <span>02</span>
            <p>
              Someone needs you?
              <br />
              Look away. Mic away.
            </p>
          </div>
          <div>
            <span>03</span>
            <p>
              Face the Mac again.
              <br />
              Your agent is still there.
            </p>
          </div>
        </div>
      </section>

      <section className="open-source" aria-labelledby="open-source-title">
        <p className="eyebrow">
          <span className="signal" /> Built in the open
        </p>
        <h2 id="open-source-title">
          Trust the boundary.
          <br />
          Read the code.
        </h2>
        <div className="open-source-copy">
          <p>
            MicAway never needs to hear your words. It reads AirPods head
            direction and changes microphone state locally. No transcription,
            account, analytics, or cloud service.
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
        <div className="install-intro">
          <p className="eyebrow">
            <span className="signal" /> Developer preview
          </p>
          <h2 id="install-title">
            Open MicAway.
            <br />
            Keep Gatekeeper on.
          </h2>
          <p>
            MicAway is open source, but this preview is not yet signed or
            notarized. macOS may ask you to confirm the first launch.
          </p>
        </div>
        <div className="install-card">
          <ol className="install-steps">
            <li className="install-step">
              <span>1</span>
              <div>
                <strong>Move it to Applications</strong>
                <p>
                  Download the Apple-silicon release, unzip it, then drag{" "}
                  <code>MicAway.app</code> into Applications.
                </p>
              </div>
            </li>
            <li className="install-step">
              <span>2</span>
              <div>
                <strong>Try opening MicAway</strong>
                <p>
                  Open it once. If macOS blocks it, go to System Settings,
                  then Privacy &amp; Security.
                </p>
                <div
                  className="settings-guide"
                  role="img"
                  aria-label="In System Settings, open Privacy and Security, scroll to Security, then choose Open Anyway for MicAway"
                >
                  <div className="settings-guide-bar">
                    <i aria-hidden="true" />
                    <i aria-hidden="true" />
                    <i aria-hidden="true" />
                    <span>System Settings</span>
                  </div>
                  <div className="settings-guide-content">
                    <small>Privacy &amp; Security / Security</small>
                    <p>MicAway was blocked from use.</p>
                    <b>Open Anyway</b>
                  </div>
                </div>
              </div>
            </li>
            <li className="install-step">
              <span>3</span>
              <div>
                <strong>Still blocked? Use Terminal</strong>
                <p>
                  Run this only for MicAway downloaded from the official GitHub
                  release.
                </p>
                <div className="terminal-command">
                  <div className="terminal-toolbar">
                    <span>Terminal</span>
                    <button type="button" onClick={copyInstallCommand}>
                      {commandCopied ? (
                        <Check aria-hidden="true" />
                      ) : (
                        <Copy aria-hidden="true" />
                      )}
                      {commandCopied ? "Copied" : "Copy"}
                    </button>
                  </div>
                  <pre>
                    <code>{installCommand}</code>
                  </pre>
                </div>
                <p className="security-warning">
                  This removes quarantine metadata from MicAway only. Never run
                  it against Applications, Downloads, or a wildcard.
                </p>
              </div>
            </li>
            <li className="install-step">
              <span>4</span>
              <div>
                <strong>Allow Motion access</strong>
                <p>
                  Wear compatible AirPods, allow Motion when macOS asks, face
                  your Mac, and calibrate once.
                </p>
                <div
                  className="permission-guide"
                  aria-label="MicAway permissions"
                >
                  <span>
                    <Check aria-hidden="true" /> Motion required
                  </span>
                  <span>Microphone not requested</span>
                  <span>Accessibility not requested</span>
                </div>
              </div>
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
            Unsigned open-source preview · Full source and SHA-256 checksum
            included
          </p>
        </div>
      </section>

      <footer>
        <span>MicAway · Free and MIT licensed</span>
        <span>Built by Akash Panchal for developers who think out loud.</span>
      </footer>
    </main>
  );
}
