//
//  PhotosPermission.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

/// Requests and observes access to the photo library.
///
/// Use `Permissions.photos` for the real implementation. `.limited` is a normal result: the user shared a selection of photos, and ``presentLimitedLibraryPicker()`` lets them change it.
public struct PhotosPermission: PhotosProviding {
    private let provider: any PhotosProviding

    /// Creates a permission backed by `provider`.
    ///
    /// - Parameter provider: The implementation that answers the calls, usually ``live``.
    public init(provider: any PhotosProviding) {
        self.provider = provider
    }

    /// The current authorization status for an access level.
    ///
    /// - Parameter access: The access level to check. Defaults to ``PhotosAccess/readWrite``.
    public func status(for access: PhotosAccess = .readWrite) async -> PermissionStatus {
        await provider.status(for: access)
    }

    /// Asks the user for photo library access if they have not decided yet.
    ///
    /// Concurrent calls for the same access level share one system prompt.
    ///
    /// - Parameter access: The access level to ask for. Defaults to ``PhotosAccess/readWrite``.
    /// - Returns: The status after the request. A denial is returned, not thrown.
    /// - Throws: ``PermissionError/missingUsageDescription(key:)`` if the Info.plist key for the level is missing, or `CancellationError` if the task is cancelled.
    public func requestAuthorization(for access: PhotosAccess = .readWrite) async throws -> PermissionStatus {
        try await provider.requestAuthorization(for: access)
    }

    /// Emits the current status for an access level and then every change.
    ///
    /// Changes are detected when the app becomes active.
    ///
    /// - Parameter access: The access level to observe. Defaults to ``PhotosAccess/readWrite``.
    /// - Returns: A stream that does not finish on its own; cancel the consuming task to stop it.
    public func statusUpdates(for access: PhotosAccess = .readWrite) -> AsyncStream<PermissionStatus> {
        provider.statusUpdates(for: access)
    }

    /// Presents the system picker that lets the user change the photos shared with the app.
    ///
    /// Returns when the user dismisses the picker.
    ///
    /// - Throws: ``PermissionError/unavailable(reason:)`` if read-write access is not limited or there is no view controller to present from.
    public func presentLimitedLibraryPicker() async throws {
        try await provider.presentLimitedLibraryPicker()
    }
}
