//
//  CaptureBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SrdzPermissionsCore

protocol CaptureBackend: Sendable {
    func currentStatus() -> PermissionStatus
    func requestAccess() async -> Bool
    func statusChanges() -> AsyncStream<Void>
}
