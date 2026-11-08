import { Download, Github } from "lucide-react";
import Image from "next/image";
import { AttentionDemo } from "@/components/attention-demo";
import { DownloadCount } from "@/components/download-count";
import { InstallGuide } from "@/components/install-guide";

const githubUrl = "https://github.com/akashp1712/micaway";
const downloadUrl = "/api/download";

const callApps = [
  { name: "Zoom", logo: "zoom.svg" },
  { name: "Microsoft Teams", logo: "teams.svg" },
  { name: "Slack", logo: "slack.svg" },
  { name: "FaceTime", logo: "facetime.png" },
  { name: "Google Meet in the browser", logo: "google-meet.svg" },
] as const;

const menuShots = [
  {
    src: "/images/menu/calibrate.png",
    title: "Set forward",
    copy: "Wear AirPods, face the Mac, and set forward once.",
    alt: "MicAway menu asking you to face your Mac and calibrate",
  },
  {
    src: "/images/menu/listening.png",
    title: "Join the call",
    copy: "Zoom, Teams, Slack, FaceTime, or Meet. MicAway turns on by itself.",
    alt: "MicAway menu showing On for this call, live while facing the Mac",
  },
  {
    src: "/images/menu/away.png",
    title: "Turn",
    copy: "Turn toward someone and you’re muted. Face the screen and you’re live.",
    alt: "MicAway menu showing On for this call, muted after turning away",
  },
] as const;

export default function HomePage() {
  return (
    <main className="site-shell">
      <a className="skip-link" href="#top">
        Skip to content
      </a>
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

      <section
        aria-labelledby="hero-title"
        className="hero"
        id="top"
        tabIndex={-1}
      >
        <Image
          alt=""
          className="hero-icon"
          height={132}
          priority
          src="/brand/micaway-app-icon.png"
          width={132}
        />
        <p className="hero-name">MicAway</p>
        <h1 id="hero-title">Turn to answer. The call mutes.</h1>
        <p className="hero-copy">
          MicAway uses AirPods head tracking to mute your Mac when you look
          away. Face the screen and your microphone comes back.
        </p>
        <div className="hero-actions">
          <a className="button button-signal" href={downloadUrl}>
            <Download aria-hidden="true" /> Get MicAway
          </a>
          <a
            className="text-link"
            href={githubUrl}
            rel="noreferrer"
            target="_blank"
          >
            <Github aria-hidden="true" /> Read the source
          </a>
        </div>
        <p className="hero-meta">
          Free and open source
          <DownloadCount prefix=" · " />
        </p>
        <p className="hero-requirements">
          macOS 14+ · AirPods with head tracking
        </p>
        <AttentionDemo />
      </section>

      <section aria-labelledby="how-title" className="how-section">
        <h2 id="how-title">Set it once. Then turn.</h2>
        <ol className="setup-gallery">
          {menuShots.map((shot, index) => (
            <li className="setup-step" key={shot.title}>
              <div className="menu-shot">
                <Image alt={shot.alt} height={321} src={shot.src} width={356} />
              </div>
              <div className="setup-caption">
                <h3>
                  <span className="step-number">{index + 1}</span>
                  {shot.title}
                </h3>
                <p>{shot.copy}</p>
              </div>
            </li>
          ))}
        </ol>
      </section>

      <section aria-labelledby="workflow-title" className="workflow-shift">
        <h2 id="workflow-title">Works in the calls you already use.</h2>
        <ul className="app-list">
          {callApps.map((app) => (
            <li className="app-chip" key={app.name}>
              <Image
                alt=""
                className="call-app-logo"
                height={28}
                src={`/brands/calls/${app.logo}`}
                width={28}
              />
              <span>{app.name}</span>
            </li>
          ))}
        </ul>
        <p className="secondary-use">
          Use dictation apps? Add them in Allowed apps. FluidVoice is manually
          verified; Wispr Flow and ChatGPT Voice still need community testing.
        </p>
        <p className="trademark-note">
          Independent project. Not affiliated with Zoom, Microsoft, Slack,
          Apple, Google, Wispr Flow, FluidVoice, or OpenAI. Product names and
          logos are trademarks of their owners.
        </p>
      </section>

      <section aria-labelledby="control-title" className="control-section">
        <h2 id="control-title">Keep it on your terms.</h2>
        <p className="control-intro">
          Automatic when you want it. Completely out of the way when you do not.
        </p>
        <div className="control-grid">
          <article className="control-card">
            <div className="control-copy">
              <span className="control-kicker">How it mutes</span>
              <h3>The room goes quiet.</h3>
              <p>
                MicAway mutes your Mac&rsquo;s microphone input. It does not
                press the call app&rsquo;s mute button, so the mic icon in Zoom,
                Teams, Slack, or Meet may still look open while nobody hears
                you. Face the Mac and MicAway restores only the input it muted.
              </p>
            </div>
            <div className="menu-shot menu-shot-embed">
              <Image
                alt="MicAway Advanced settings with Allowed apps, Never mute during, and Sensitivity"
                height={509}
                src="/images/menu/advanced.png"
                width={356}
              />
            </div>
          </article>
          <article className="control-card">
            <div className="control-copy">
              <span className="control-kicker">Pause Anywhere</span>
              <h3>Move the laptop without fighting it.</h3>
              <p>
                Switch turnaway muting off while walking around the office. Turn
                it back on and MicAway safely re-centers to your current
                position.
              </p>
            </div>
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
          locally. No microphone permission or audio recording.
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
          This developer preview is not yet Developer ID signed or notarized.
          macOS may ask you to confirm the first launch.
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
