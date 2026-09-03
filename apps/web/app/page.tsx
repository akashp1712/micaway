import { Download, Github } from "lucide-react";
import Image from "next/image";
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
    href: "https://help.openai.com/en/articles/20001274/?utm_source=micaway&utm_medium=referral&utm_campaign=compatible_voice_apps",
  },
  {
    name: "Wispr Flow",
    logo: "/brands/wispr-flow.png",
    className: "wispr-logo",
    href: "https://wisprflow.ai/?utm_source=micaway&utm_medium=referral&utm_campaign=compatible_voice_apps",
  },
  {
    name: "FluidVoice",
    logo: "/brands/fluidvoice-icon.png",
    className: "fluidvoice-logo",
    href: "https://fluidvoice.org/?utm_source=micaway&utm_medium=referral&utm_campaign=compatible_voice_apps",
  },
] as const;

const menuShots = [
  {
    src: "/images/menu/calibrate.png",
    title: "Calibrate",
    copy: "Wear your AirPods, face your Mac, and set forward once.",
    alt: "MicAway menu asking you to face your Mac and calibrate",
  },
  {
    src: "/images/menu/listening.png",
    title: "Talk",
    copy: "Face forward. MicAway leaves your input available.",
    alt: "MicAway menu showing Listening while facing the Mac",
  },
  {
    src: "/images/menu/away.png",
    title: "Turn",
    copy: "Look toward someone beside you. The aside stays out.",
    alt: "MicAway menu showing Not for your Mac after turning away",
  },
] as const;

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
          {menuShots.map((shot) => (
            <article className="setup-step" key={shot.title}>
              <div className="menu-shot">
                <Image alt={shot.alt} height={321} src={shot.src} width={356} />
              </div>
              <div className="setup-caption">
                <h3>{shot.title}</h3>
                <p>{shot.copy}</p>
              </div>
            </article>
          ))}
        </div>
      </section>

      <section aria-labelledby="workflow-title" className="workflow-shift">
        <h2 id="workflow-title">Works where voice stays open.</h2>
        <div className="app-list">
          {voiceApps.map((app) => (
            <a
              className="app-chip"
              href={app.href}
              key={app.name}
              rel="noreferrer"
              target="_blank"
            >
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
            </a>
          ))}
        </div>
        <p className="trademark-note">
          Independent project. Not affiliated with Wispr Flow, FluidVoice, or
          OpenAI.
        </p>
      </section>

      <section aria-labelledby="control-title" className="control-section">
        <h2 id="control-title">Keep it on your terms.</h2>
        <p className="control-intro">
          Automatic when you want it. Completely out of the way when you do not.
        </p>
        <div className="control-grid">
          <article className="control-card">
            <span className="control-kicker">Selected Apps</span>
            <h3>Use it for dictation, not meetings.</h3>
            <p>
              Choose the voice apps where turnaway muting belongs. If an
              unselected meeting app is using your microphone, MicAway stays
              inactive.
            </p>
            <div className="menu-shot menu-shot-embed">
              <Image
                alt="MicAway Advanced settings with Use in and Sensitivity"
                height={397}
                src="/images/menu/advanced.png"
                width={356}
              />
            </div>
          </article>
          <article className="control-card">
            <span className="control-kicker">Pause Anywhere</span>
            <h3>Move the laptop without fighting it.</h3>
            <p>
              Switch turnaway muting off while walking around the office. Turn
              it back on and MicAway safely re-centers to your current position.
            </p>
            <div className="menu-shot menu-shot-embed">
              <Image
                alt="MicAway menu paused with turnaway muting off"
                height={321}
                src="/images/menu/paused.png"
                width={356}
              />
            </div>
          </article>
        </div>
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
