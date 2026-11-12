//
//  AVCaptureBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

#if os(iOS)
import AVFoundation
import SrdzPermissionsCore

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
        ApplicationActivity.didBecomeActiveSignals()
    }
}
#endif
