//
//  PhotosBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

protocol PhotosBackend: Sendable {
    func currentStatus(for access: PhotosAccess) -> PermissionStatus
    func requestAccess(for access: PhotosAccess) async
    func statusChanges() -> AsyncStream<Void>
    func presentLimitedPicker() async throws
}
