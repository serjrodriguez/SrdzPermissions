//
//  CapturePermission+Live.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

#if os(iOS)
import AVFoundation

extension CameraPermission {
    /// The real implementation, backed by AVFoundation.
    public static let live = CameraPermission(
        provider: AuthorizationService<Unscoped>.makeCaptureService(
            backend: AVCaptureBackend(mediaType: .video),
            usageDescriptionKey: "NSCameraUsageDescription"
        )
    )
}

extension MicrophonePermission {
    /// The real implementation, backed by AVFoundation.
    public static let live = MicrophonePermission(
        provider: AuthorizationService<Unscoped>.makeCaptureService(
            backend: AVCaptureBackend(mediaType: .audio),
            usageDescriptionKey: "NSMicrophoneUsageDescription"
        )
    )
}
#endif
