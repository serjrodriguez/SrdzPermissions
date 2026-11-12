//
//  NotificationProviding.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

public protocol NotificationProviding: Sendable {
    var status: PermissionStatus { get async }

    func requestAuthorization(options: NotificationOptions) async throws -> PermissionStatus

    func statusUpdates() -> AsyncStream<PermissionStatus>
}
