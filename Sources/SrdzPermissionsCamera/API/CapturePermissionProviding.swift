//
//  CapturePermissionProviding.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SrdzPermissionsCore

public protocol CapturePermissionProviding: Sendable {
    var status: PermissionStatus { get async }

    func requestAuthorization() async throws -> PermissionStatus

    func statusUpdates() -> AsyncStream<PermissionStatus>
}
