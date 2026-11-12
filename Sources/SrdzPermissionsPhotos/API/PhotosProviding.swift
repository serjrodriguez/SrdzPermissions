//
//  PhotosProviding.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

/// A source of photo library authorization status. ``PhotosPermission`` is the facade apps use; conform to this protocol to provide a fake.
public protocol PhotosProviding: Sendable {
    /// The current authorization status for an access level.
    ///
    /// - Parameter access: The access level to check.
    func status(for access: PhotosAccess) async -> PermissionStatus

    /// Asks the user for photo library access if they have not decided yet.
    ///
    /// - Parameter access: The access level to ask for.
    /// - Returns: The status after the request. A denial is returned, not thrown.
    /// - Throws: A ``PermissionError`` if the request cannot be made, or `CancellationError` if the task is cancelled.
    func requestAuthorization(for access: PhotosAccess) async throws -> PermissionStatus

    /// Emits the current status for an access level and then every change.
    ///
    /// - Parameter access: The access level to observe.
    /// - Returns: A stream that does not finish on its own; cancel the consuming task to stop it.
    func statusUpdates(for access: PhotosAccess) -> AsyncStream<PermissionStatus>

    /// Presents the system picker that lets the user change the photos shared with the app.
    ///
    /// - Throws: ``PermissionError/unavailable(reason:)`` if access is not limited or there is nothing to present from.
    func presentLimitedLibraryPicker() async throws
}
