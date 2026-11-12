//
//  PhotosPermission.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

public struct PhotosPermission: PhotosProviding {
    private let provider: any PhotosProviding

    public init(provider: any PhotosProviding) {
        self.provider = provider
    }

    public func status(for access: PhotosAccess = .readWrite) async -> PermissionStatus {
        await provider.status(for: access)
    }

    public func requestAuthorization(for access: PhotosAccess = .readWrite) async throws -> PermissionStatus {
        try await provider.requestAuthorization(for: access)
    }

    public func statusUpdates(for access: PhotosAccess = .readWrite) -> AsyncStream<PermissionStatus> {
        provider.statusUpdates(for: access)
    }

    public func presentLimitedLibraryPicker() async throws {
        try await provider.presentLimitedLibraryPicker()
    }
}
