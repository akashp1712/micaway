import Foundation

enum ApplicationScope: String, CaseIterable, Identifiable {
    case everyApp
    case selectedApps

    var id: String { rawValue }

    var label: String {
        switch self {
        case .everyApp: "Every app"
        case .selectedApps: "Selected apps"
        }
    }
}

struct ScopedApplication: Codable, Hashable, Identifiable {
    let bundleIdentifier: String
    let name: String

    var id: String { bundleIdentifier }
}
