//
//  AVCaptureBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

#if os(iOS)
import AVFoundation
import SrdzPermissionsCore
import UIKit

struct AVCaptureBackend: CaptureBackend {
    let mediaType: AVMediaType

    func currentStatus() -> PermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: mediaType) {
        case .notDetermined: .notDetermined
        case .restricted: .restricted
        case .denied: .denied
        case .authorized: .authorized
        @unknown default: .notDetermined
        }
    }

    func requestAccess() async -> Bool {
        await AVCaptureDevice.requestAccess(for: mediaType)
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
}
#endif
