//
//  AppTrackingBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
import AppTrackingTransparency
import Foundation
import SrdzPermissionsCore
import UIKit

struct AppTrackingBackend: TrackingBackend {
    func currentStatus() -> PermissionStatus {
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorized: .authorized
        @unknown default: .notDetermined
        }
    }

    func requestAccess() async {
        await Self.waitUntilActive()
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    func statusChanges() -> AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                for await _ in NotificationCenter.default.notifications(named: UIApplication.didBecomeActiveNotification) {
                    continuation.yield()
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    @MainActor
    private static func waitUntilActive() async {
        guard UIApplication.shared.applicationState != .active else { return }
        for await _ in NotificationCenter.default.notifications(named: UIApplication.didBecomeActiveNotification) {
            return
        }
    }
}
#endif
