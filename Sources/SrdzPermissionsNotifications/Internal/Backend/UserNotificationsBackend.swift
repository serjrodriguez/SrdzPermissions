//
//  UserNotificationsBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
import Foundation
import SrdzPermissionsCore
import UserNotifications

struct UserNotificationsBackend: NotificationBackend {
    func currentStatus() async -> PermissionStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return PermissionStatus(settings.authorizationStatus)
    }

    func requestAuthorization(_ options: NotificationOptions) async throws {
        _ = try await UNUserNotificationCenter.current().requestAuthorization(options: options.userNotificationsValue)
    }

    func statusChanges() -> AsyncStream<Void> {
        ApplicationActivity.didBecomeActiveSignals()
    }
}

private extension PermissionStatus {
    init(_ status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .denied: self = .denied
        case .authorized, .ephemeral: self = .authorized
        case .provisional: self = .limited
        @unknown default: self = .notDetermined
        }
    }
}

private extension NotificationOptions {
    var userNotificationsValue: UNAuthorizationOptions {
        var result: UNAuthorizationOptions = []
        if contains(.alert) { result.insert(.alert) }
        if contains(.sound) { result.insert(.sound) }
        if contains(.badge) { result.insert(.badge) }
        if contains(.provisional) { result.insert(.provisional) }
        return result
    }
}
#endif
