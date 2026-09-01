type AppShotState = "calibrate" | "listening" | "away";

const shots: Record<
  AppShotState,
  {
    yaw: string;
    title: string;
    detail: string;
    message: string;
    action: string;
    listening: boolean;
  }
> = {
  calibrate: {
    yaw: "0°",
    title: "Face your Mac",
    detail: "Calibrate once while looking forward.",
    message: "Motion connected. Face your Mac and calibrate.",
    action: "Calibrate",
    listening: false,
  },
  listening: {
    yaw: "0°",
    title: "Listening",
    detail: "Turn away to pause voice input.",
    message: "Forward set. The boundary is ready.",
    action: "Calibrate",
    listening: true,
  },
  away: {
    yaw: "42°",
    title: "Not for your Mac",
    detail: "Your side conversation stays out.",
    message: "Face your Mac again to continue.",
    action: "Calibrate",
    listening: false,
  },
};

export function AppShot({
  state,
  chrome = "full",
}: {
  state: AppShotState;
  chrome?: "full" | "popover";
}) {
  const shot = shots[state];

  return (
    <div
      aria-hidden="true"
      className={`app-shot app-shot-${state} chrome-${chrome}`}
    >
      {chrome === "full" ? (
        <div className="shot-menubar">
          <span>File</span>
          <span>Edit</span>
          <b>MicAway</b>
          <em>Tue 9:41</em>
        </div>
      ) : null}
      <div className="shot-popover">
        <div className="shot-titlebar">
          <span>
            <i className={shot.listening ? "is-live" : undefined} /> MicAway
          </span>
          <code>{shot.yaw}</code>
        </div>
        <h3>{shot.title}</h3>
        <p>{shot.detail}</p>
        <hr />
        <div className="shot-toggle">
          <span>Turnaway guard</span>
          <i />
        </div>
        <div className="shot-toggle">
          <span>Mute mic when turned away</span>
          <i />
        </div>
        <small>{shot.message}</small>
        <div className="shot-actions">
          <button tabIndex={-1} type="button">
            {shot.action}
          </button>
          <button tabIndex={-1} type="button">
            Quit
          </button>
        </div>
      </div>
    </div>
  );
}
