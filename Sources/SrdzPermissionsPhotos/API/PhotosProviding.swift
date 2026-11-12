//
//  PhotosProviding.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

public protocol PhotosProviding: Sendable {
    func status(for access: PhotosAccess) async -> PermissionStatus

    func requestAuthorization(for access: PhotosAccess) async throws -> PermissionStatus

    func statusUpdates(for access: PhotosAccess) -> AsyncStream<PermissionStatus>

    func presentLimitedLibraryPicker() async throws
}
