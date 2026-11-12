//
//  NotificationBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

protocol NotificationBackend: Sendable {
    func currentStatus() async -> PermissionStatus
    func requestAuthorization(_ options: NotificationOptions) async throws
    func statusChanges() -> AsyncStream<Void>
}
