"use client";

import { Check, Copy } from "lucide-react";
import { useState } from "react";

const installCommand = `xattr -cr "/Applications/MicAway.app"
open "/Applications/MicAway.app"`;

export function InstallGuide() {
  const [copied, setCopied] = useState(false);

  const copyCommand = async () => {
    await navigator.clipboard.writeText(installCommand);
    setCopied(true);
    window.setTimeout(() => setCopied(false), 1800);
  };

  return (
    <div className="install-guide">
      <ol className="install-steps">
        <li>
          <span>1</span>
          <div>
            <strong>Move it to Applications</strong>
            <p>
              Download the universal release, unzip it, then drag{" "}
              <code>MicAway.app</code> into Applications.
            </p>
          </div>
        </li>
        <li>
          <span>2</span>
          <div>
            <strong>Try opening MicAway</strong>
            <p>
              If macOS blocks it, open System Settings, then Privacy &amp;
              Security. Scroll to Security and choose Open Anyway.
            </p>
            <div
              aria-label="Visual guide showing Open Anyway in Privacy and Security settings"
              className="settings-guide"
              role="img"
            >
              <div className="settings-guide-bar">
                <i aria-hidden="true" />
                <i aria-hidden="true" />
                <i aria-hidden="true" />
                <small>Visual guide</small>
              </div>
              <div className="settings-guide-content">
                <span>Privacy &amp; Security / Security</span>
                <p>MicAway was blocked from use.</p>
                <b>Open Anyway</b>
              </div>
            </div>
          </div>
        </li>
        <li>
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
                <button onClick={copyCommand} type="button">
                  {copied ? (
                    <Check aria-hidden="true" />
                  ) : (
                    <Copy aria-hidden="true" />
                  )}
                  {copied ? "Copied" : "Copy"}
                </button>
              </div>
              <pre>
                <code>{installCommand}</code>
              </pre>
            </div>
            <p className="security-warning">
              This removes quarantine metadata from MicAway only. Never run it
              against Applications, Downloads, or a wildcard.
            </p>
          </div>
        </li>
        <li>
          <span>4</span>
          <div>
            <strong>Allow Motion access</strong>
            <p>
              Wear compatible AirPods, allow Motion when macOS asks, face your
              Mac, and calibrate once.
            </p>
            <div className="permission-guide">
              <span>
                <Check aria-hidden="true" /> Motion required
              </span>
              <span>Microphone not requested</span>
              <span>Accessibility not requested</span>
            </div>
          </div>
        </li>
      </ol>
    </div>
  );
}
