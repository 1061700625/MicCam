import Foundation
import SwiftUI

enum PrivacyService: String, CaseIterable, Identifiable {
    case microphone = "kTCCServiceMicrophone"
    case camera = "kTCCServiceCamera"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .microphone: return "麦克风"
        case .camera: return "摄像头"
        }
    }

    var systemSettingsPane: String {
        switch self {
        case .microphone:
            return "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        case .camera:
            return "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera"
        }
    }
}

enum TCCDecision: Equatable, Hashable {
    case allowed
    case denied
    case notDetermined
    case limited
    case unknown(String)

    var label: String {
        switch self {
        case .allowed: return "已允许"
        case .denied: return "已拒绝"
        case .notDetermined: return "未请求/未记录"
        case .limited: return "受限"
        case .unknown(let value): return "未知：\(value)"
        }
    }

    var color: Color {
        switch self {
        case .allowed: return .green
        case .denied: return .red
        case .notDetermined: return .secondary
        case .limited: return .orange
        case .unknown: return .gray
        }
    }
}

struct InstalledApp: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleIdentifier: String
    let path: String
    var iconData: Data?
    var microphone: TCCDecision
    var camera: TCCDecision

    var hasAnyRecord: Bool {
        microphone != .notDetermined || camera != .notDetermined
    }
}

struct TCCEntry: Hashable {
    let service: PrivacyService
    let client: String
    let decision: TCCDecision
    let lastModified: Date?
}
