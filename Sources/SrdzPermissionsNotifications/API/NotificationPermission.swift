//
//  NotificationPermission.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

public struct NotificationPermission: NotificationProviding {
    private let provider: any NotificationProviding

    public init(provider: any NotificationProviding) {
        self.provider = provider
    }

    public var status: PermissionStatus {
        get async { await provider.status }
    }

    public func requestAuthorization(options: NotificationOptions = .standard) async throws -> PermissionStatus {
        try await provider.requestAuthorization(options: options)
    }

    public func statusUpdates() -> AsyncStream<PermissionStatus> {
        provider.statusUpdates()
    }
}
