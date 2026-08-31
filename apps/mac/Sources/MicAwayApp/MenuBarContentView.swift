import MicAwayCore
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel

    private var signalColor: Color {
        switch model.intentState {
        case .needsCalibration: .secondary
        case .listening: Color(red: 0.11, green: 0.50, blue: 0.29)
        case .turnaway: .primary.opacity(0.32)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Circle()
                    .fill(signalColor)
                    .frame(width: 8, height: 8)
                Text("micaway")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                Spacer()
                Text("\(Int(model.relativeYawDegrees.rounded()))°")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 24)

            Text(model.statusTitle)
                .font(.system(size: 27, weight: .medium, design: .rounded))
                .contentTransition(.numericText())
            Text(model.statusDetail)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.top, 5)

            Divider()
                .padding(.vertical, 20)

            Toggle("MicAway guard", isOn: $model.guardEnabled)
                .toggleStyle(.switch)

            Toggle("Mute default input", isOn: $model.microphoneGateEnabled)
                .toggleStyle(.switch)
                .disabled(!model.microphoneGateAvailable)
                .padding(.top, 10)

            Text(model.message)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            HStack(spacing: 8) {
                Button("Calibrate") { model.calibrate() }
                    .keyboardShortcut("r", modifiers: [.command])
                    .disabled(!model.canCalibrate)
                Spacer()
                Button("Quit") { model.quit() }
                    .keyboardShortcut("q", modifiers: [.command])
            }
            .padding(.top, 18)
        }
        .padding(20)
        .frame(width: 320)
        .animation(.easeOut(duration: 0.16), value: model.intentState)
    }
}
