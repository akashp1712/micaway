import MicAwayCore
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel
    @State private var advancedExpanded = false

    private var signalColor: Color {
        if !model.turnawayEnabled || !model.activeApplicationAllowed {
            return .secondary
        }
        return switch model.intentState {
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
                Text("MicAway")
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
                .padding(.vertical, 16)

            Toggle("Turnaway muting", isOn: $model.turnawayEnabled)
                .toggleStyle(.switch)

            Picker("Use in", selection: $model.applicationScope) {
                ForEach(ApplicationScope.allCases) { scope in
                    Text(scope.label).tag(scope)
                }
            }
            .pickerStyle(.menu)
            .padding(.top, 8)

            if model.applicationScope == .selectedApps {
                Menu("Apps (\(model.selectedApplications.count))") {
                    Button(
                        model.activeApplicationSelected
                            ? "Remove \(model.activeApplicationName)"
                            : "Add \(model.activeApplicationName)"
                    ) {
                        model.setActiveApplicationAllowed(!model.activeApplicationSelected)
                    }
                    .disabled(model.activeApplication == nil)

                    if !model.selectedApplications.isEmpty {
                        Divider()
                        ForEach(model.selectedApplications) { application in
                            Button("Remove \(application.name)") {
                                model.removeSelectedApplication(application)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }

            DisclosureGroup("Advanced", isExpanded: $advancedExpanded) {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Sensitivity", selection: $model.sensitivity) {
                        ForEach(Sensitivity.allCases) { level in
                            Text(level.label).tag(level)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(model.message)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .font(.system(size: 12))
            .padding(.top, 10)

            HStack(spacing: 8) {
                if model.canCalibrate {
                    Button("Calibrate") { model.calibrate() }
                        .keyboardShortcut("r", modifiers: [.command])
                } else {
                    Button("Retry") { model.retryMotion() }
                        .keyboardShortcut("r", modifiers: [.command])
                }
                Spacer()
                Button("Quit") { model.quit() }
                    .keyboardShortcut("q", modifiers: [.command])
            }
            .padding(.top, 16)
        }
        .padding(18)
        .frame(width: 300)
        .animation(.easeOut(duration: 0.16), value: model.intentState)
    }
}
