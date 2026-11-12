//
//  PhotoLibraryBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
import Foundation
import Photos
import PhotosUI
import SrdzPermissionsCore
import UIKit

struct PhotoLibraryBackend: PhotosBackend {
    func currentStatus(for access: PhotosAccess) -> PermissionStatus {
        PermissionStatus(PHPhotoLibrary.authorizationStatus(for: access.photosLevel))
    }

    func requestAccess(for access: PhotosAccess) async {
        _ = await PHPhotoLibrary.requestAuthorization(for: access.photosLevel)
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

    func presentLimitedPicker() async throws {
        try await Self.present()
    }

    @MainActor
    private static func present() async throws {
        guard let controller = topViewController() else {
            throw PermissionError.unavailable(reason: "There is no view controller to present the picker from.")
        }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: controller) { _ in
                continuation.resume()
            }
        }
    }

    @MainActor
    private static func topViewController() -> UIViewController? {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var top = scene?.keyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

private extension PhotosAccess {
    var photosLevel: PHAccessLevel {
        switch self {
        case .readWrite: .readWrite
        case .addOnly: .addOnly
        }
    }
}

private extension PermissionStatus {
    init(_ status: PHAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .restricted: self = .restricted
        case .denied: self = .denied
        case .authorized: self = .authorized
        case .limited: self = .limited
        @unknown default: self = .notDetermined
        }
    }
}
#endif
