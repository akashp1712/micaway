import MicAwayCore
import SwiftUI

private enum SnapshotCaptureKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var snapshotCapture: Bool {
        get { self[SnapshotCaptureKey.self] }
        set { self[SnapshotCaptureKey.self] = newValue }
    }
}

/// Drawn switch for marketing captures. Offscreen `NSSwitch` stays gray even when on.
private struct SnapshotMacSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 0) {
            configuration.label
            Spacer(minLength: 8)
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                Capsule()
                    .fill(
                        configuration.isOn
                            ? Color(nsColor: .controlAccentColor)
                            : Color(white: 0.82)
                    )
                Circle()
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.18), radius: 1.5, y: 0.5)
                    .padding(1.2)
            }
            .frame(width: 38, height: 22)
        }
    }
}

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel
    @State private var advancedExpanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.snapshotCapture) private var snapshotCapture

    init(model: AppModel, advancedExpanded: Bool = false) {
        self.model = model
        _advancedExpanded = State(initialValue: advancedExpanded)
    }

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
                .lineLimit(1)
                .frame(maxWidth: .infinity, minHeight: 33, alignment: .leading)
            Text(model.statusDetail)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 32, alignment: .topLeading)
                .padding(.top, 5)

            Divider()
                .padding(.vertical, 16)

            VStack(spacing: 2) {
                turnawayToggle
                    .controlSize(.regular)
                    .frame(minHeight: 24)

                Button {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        advancedExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Advanced")
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(advancedExpanded ? 90 : 0))
                            .animation(
                                reduceMotion ? nil : .easeOut(duration: 0.12),
                                value: advancedExpanded
                            )
                    }
                    .contentShape(Rectangle())
                    .frame(minHeight: 24)
                }
                .buttonStyle(.plain)
                .accessibilityValue(advancedExpanded ? "Expanded" : "Collapsed")
                .accessibilityHint(
                    advancedExpanded
                        ? "Hides advanced settings"
                        : "Shows advanced settings"
                )
            }

            if advancedExpanded {
                VStack(spacing: 2) {
                    SettingsPicker("Use in", selection: $model.applicationScope) {
                        ForEach(ApplicationScope.allCases) { scope in
                            Text(scope.label).tag(scope)
                        }
                    }

                    if model.applicationScope == .selectedApps {
                        HStack(spacing: 8) {
                            Text("Allowed apps")
                            Spacer(minLength: 8)
                            Menu {
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
                            } label: {
                                Text("\(model.selectedApplications.count)")
                            }
                            .fixedSize()
                        }
                        .frame(minHeight: 24)
                    }

                    HStack(spacing: 8) {
                        Text("Never mute during")
                        Spacer(minLength: 8)
                        Menu {
                            Button(
                                model.activeApplicationProtected
                                    ? "Remove \(model.activeApplicationName)"
                                    : "Add \(model.activeApplicationName)"
                            ) {
                                model.setActiveApplicationProtected(!model.activeApplicationProtected)
                            }
                            .disabled(model.activeApplication == nil)

                            if !model.protectedApplications.isEmpty {
                                Divider()
                                ForEach(model.protectedApplications) { application in
                                    Button("Remove \(application.name)") {
                                        model.removeProtectedApplication(application)
                                    }
                                }
                            }
                        } label: {
                            Text("\(model.protectedApplications.count)")
                        }
                        .fixedSize()
                    }
                    .frame(minHeight: 24)

                    Text("In a meeting in your browser? Bring it forward and add it here.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    sensitivitySlider

                    Text(model.message)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 6)
                }
                .padding(.top, 4)
            }

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
        .font(.system(size: 13))
    }

    /// Continuous sensitivity control. The stored value is the "mute past this
    /// angle" degree; a *smaller* angle is *more* sensitive. The slider position
    /// is mirrored so dragging right raises sensitivity (High), matching the
    /// Low→High labels, while the readout shows the actual mute angle.
    private var sensitivitySlider: some View {
        let min = SensitivityLimits.minDegrees
        let max = SensitivityLimits.maxDegrees
        let sliderBinding = Binding<Double>(
            get: { min + max - model.turnAngleDegrees },
            set: { model.turnAngleDegrees = (min + max - $0).rounded() }
        )
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text("Sensitivity")
                Spacer(minLength: 8)
                Text("Mutes past \(Int(model.turnAngleDegrees.rounded()))°")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            HStack(spacing: 8) {
                Text("Low")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                Slider(value: sliderBinding, in: min...max)
                    .controlSize(.small)
                Text("High")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(minHeight: 24)
    }

    @ViewBuilder
    private var turnawayToggle: some View {
        let label = HStack(spacing: 8) {
            Text("Turnaway muting")
            Text("⌥⌘M")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }

        if snapshotCapture {
            Toggle(isOn: $model.turnawayEnabled) { label }
                .toggleStyle(SnapshotMacSwitchStyle())
        } else {
            Toggle(isOn: $model.turnawayEnabled) { label }
                .toggleStyle(.switch)
        }
    }
}

private struct SettingsPicker<SelectionValue: Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue
    @ViewBuilder var content: () -> Content

    init(
        _ title: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        _selection = selection
        self.content = content
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
            Spacer(minLength: 8)
            Picker(title, selection: $selection, content: content)
                .pickerStyle(.menu)
                .labelsHidden()
                .fixedSize()
        }
        .frame(minHeight: 24)
    }
}
