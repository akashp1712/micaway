import MicAwayCore
import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var model: AppModel
    @State private var advancedExpanded = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

            Toggle("Turnaway muting", isOn: $model.turnawayEnabled)
                .toggleStyle(.switch)

            DisclosureGroup("Advanced", isExpanded: $advancedExpanded) {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Use in", selection: $model.applicationScope) {
                        ForEach(ApplicationScope.allCases) { scope in
                            Text(scope.label).tag(scope)
                        }
                    }
                    .pickerStyle(.menu)

                    if model.applicationScope == .selectedApps {
                        Menu("Allowed apps (\(model.selectedApplications.count))") {
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
                    }

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
            .disclosureGroupStyle(RowDisclosureGroupStyle())
            .font(.system(size: 12))
            .padding(.top, 8)

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
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: advancedExpanded)
    }
}

/// Makes the whole Advanced row the hit target — native DisclosureGroup on
/// macOS only accepts clicks on the chevron, which is too small in a popover.
private struct RowDisclosureGroupStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Header(configuration: configuration)
            if configuration.isExpanded {
                configuration.content
            }
        }
    }

    private struct Header: View {
        let configuration: DisclosureGroupStyleConfiguration
        @State private var hovered = false

        var body: some View {
            Button {
                configuration.isExpanded.toggle()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(configuration.isExpanded ? 90 : 0))
                    configuration.label
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(hovered ? 0.06 : 0))
                )
                .padding(.horizontal, -6)
            }
            .buttonStyle(.plain)
            .onHover { hovered = $0 }
            .accessibilityValue(configuration.isExpanded ? "Expanded" : "Collapsed")
            .accessibilityHint(
                configuration.isExpanded
                    ? "Hides advanced settings"
                    : "Shows advanced settings"
            )
        }
    }
}
