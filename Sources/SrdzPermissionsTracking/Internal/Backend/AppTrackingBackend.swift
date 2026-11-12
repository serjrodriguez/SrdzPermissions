//
//  AppTrackingBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
import AppTrackingTransparency
import SrdzPermissionsCore

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
        await ApplicationActivity.waitUntilActive()
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    func statusChanges() -> AsyncStream<Void> {
        ApplicationActivity.didBecomeActiveSignals()
    }
}
#endif
