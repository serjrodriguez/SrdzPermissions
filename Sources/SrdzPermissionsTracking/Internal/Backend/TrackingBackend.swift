//
//  TrackingBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

protocol TrackingBackend: Sendable {
    func currentStatus() -> PermissionStatus
    func requestAccess() async
    func statusChanges() -> AsyncStream<Void>
}
