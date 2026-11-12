//
//  DemoFeature.swift
//  SrdzPermissionsXCFrameworkDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

enum DemoFeature: String, CaseIterable, Identifiable {
    case location
    case capture
    case bluetooth
    case notifications
    case tracking
    case photos
    case biometrics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .location: "Location"
        case .capture: "Camera & Microphone"
        case .bluetooth: "Bluetooth"
        case .notifications: "Notifications"
        case .tracking: "Tracking"
        case .photos: "Photos"
        case .biometrics: "Face ID & Touch ID"
        }
    }

    var summary: String {
        switch self {
        case .location: "Authorization, current location and updates"
        case .capture: "Two permissions sharing one view model"
        case .bluetooth: "Permission plus radio state"
        case .notifications: "Alerts, sounds and badges"
        case .tracking: "App Tracking Transparency"
        case .photos: "Limited access and the selection picker"
        case .biometrics: "Availability and authentication"
        }
    }

    var systemImage: String {
        switch self {
        case .location: "location"
        case .capture: "camera"
        case .bluetooth: "antenna.radiowaves.left.and.right"
        case .notifications: "bell"
        case .tracking: "hand.raised"
        case .photos: "photo"
        case .biometrics: "faceid"
        }
    }
}
