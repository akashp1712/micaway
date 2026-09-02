import { Download, Github } from "lucide-react";
import Image from "next/image";
import { AppShot } from "@/components/app-shot";
import { AttentionDemo } from "@/components/attention-demo";
import { DownloadCount } from "@/components/download-count";
import { InstallGuide } from "@/components/install-guide";

const githubUrl = "https://github.com/akashp1712/micaway";
const downloadUrl = "/api/download";

const voiceApps = [
  {
    name: "ChatGPT Voice",
    logo: "/brands/chatgpt.webp",
    className: "chatgpt-logo",
  },
  {
    name: "Wispr Flow",
    logo: "/brands/wispr-flow.png",
    className: "wispr-logo",
  },
  {
    name: "FluidVoice",
    logo: "/brands/fluidvoice-mark.png",
    className: "fluidvoice-logo",
  },
] as const;

const setupSteps = [
  {
    number: "1",
    title: "Calibrate",
    copy: "Wear your AirPods, face your Mac, and set forward once.",
    state: "calibrate" as const,
  },
  {
    number: "2",
    title: "Talk",
    copy: "Face forward. MicAway leaves your input available.",
    state: "listening" as const,
  },
  {
    number: "3",
    title: "Turn",
    copy: "Look toward someone beside you. The aside stays out.",
    state: "away" as const,
  },
];

export default function HomePage() {
  return (
    <main className="site-shell">
      <nav aria-label="Main navigation" className="site-nav">
        <a aria-label="MicAway home" className="wordmark" href="#top">
          <Image alt="" height={22} src="/brand/micaway-mark.svg" width={22} />
          MicAway
        </a>
        <div className="nav-actions">
          <a href={githubUrl} rel="noreferrer" target="_blank">
            GitHub
          </a>
          <a className="nav-download" href={downloadUrl}>
            Download
          </a>
        </div>
      </nav>

      <section aria-labelledby="hero-title" className="hero" id="top">
        <Image
          alt=""
          className="hero-icon"
          height={132}
          priority
          src="/brand/micaway-app-icon.png"
          width={132}
        />
        <p className="hero-name">MicAway</p>
        <h1 id="hero-title">Not every word is a prompt.</h1>
        <p className="hero-copy">
          Face your Mac to speak. Look away, and MicAway mutes the microphone on
          your machine — without ever hearing you.
        </p>
        <div className="hero-actions">
          <a className="button button-signal" href={downloadUrl}>
            <Download aria-hidden="true" /> Download for Mac
          </a>
          <a
            className="text-link"
            href={githubUrl}
            rel="noreferrer"
            target="_blank"
          >
            View on GitHub
          </a>
        </div>
        <AttentionDemo />
      </section>

      <section aria-labelledby="how-title" className="how-section">
        <h2 id="how-title">Set it once. Then turn.</h2>
        <div className="setup-gallery">
          {setupSteps.map((step) => (
            <article className="setup-step" key={step.number}>
              <AppShot state={step.state} />
              <div className="setup-caption">
                <h3>
                  <span>{step.number}</span>
                  {step.title}
                </h3>
                <p>{step.copy}</p>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section aria-labelledby="workflow-title" className="workflow-shift">
        <h2 id="workflow-title">Works where voice stays open.</h2>
        <div className="app-list">
          {voiceApps.map((app) => (
            <article className="app-chip" key={app.name}>
              <span className={`app-logo ${app.className}`}>
                <Image
                  alt=""
                  height={40}
                  src={app.logo}
                  unoptimized
                  width={40}
                />
              </span>
              <h3>{app.name}</h3>
            </article>
          ))}
        </div>
        <p className="trademark-note">
          Independent project. Not affiliated with Wispr Flow, FluidVoice, or
          OpenAI.
        </p>
      </section>

      <section aria-labelledby="trust-title" className="trust-section">
        <h2 id="trust-title">It never hears you.</h2>
        <p className="trust-copy">
          MicAway reads AirPods head direction and changes microphone state
          locally.
        </p>
        <ul className="trust-points">
          <li>No transcription.</li>
          <li>No account.</li>
          <li>No network.</li>
        </ul>
        <a
          className="text-link"
          href={githubUrl}
          rel="noreferrer"
          target="_blank"
        >
          <Github aria-hidden="true" /> Read the source
        </a>
      </section>

      <section aria-labelledby="install-title" className="install-section">
        <Image
          alt=""
          className="install-icon"
          height={88}
          src="/brand/micaway-app-icon.png"
          width={88}
        />
        <h2 id="install-title">Open the preview.</h2>
        <p className="install-note">
          MicAway is open source, but this preview is not yet signed or
          notarized. macOS may ask you to confirm the first launch. ·{" "}
          <DownloadCount /> downloads
        </p>
        <InstallGuide />
        <a className="button button-signal" href={downloadUrl}>
          <Download aria-hidden="true" /> Get MicAway
        </a>
      </section>

      <footer>
        <a className="wordmark footer-wordmark" href="#top">
          <Image alt="" height={18} src="/brand/micaway-mark.svg" width={18} />
          MicAway
        </a>
        <span>MIT licensed</span>
      </footer>
    </main>
  );
}
