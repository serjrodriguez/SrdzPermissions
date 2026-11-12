//
//  CapturePermission+Live.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

#if os(iOS)
import AVFoundation

extension CameraPermission {
    public static let live = CameraPermission(
        provider: CapturePermissionService(
            backend: AVCaptureBackend(mediaType: .video),
            usageDescriptionKey: "NSCameraUsageDescription"
        )
    )
}

extension MicrophonePermission {
    public static let live = MicrophonePermission(
        provider: CapturePermissionService(
            backend: AVCaptureBackend(mediaType: .audio),
            usageDescriptionKey: "NSMicrophoneUsageDescription"
        )
    )
}
#endif
