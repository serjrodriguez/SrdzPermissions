//
//  TrackingPermission.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

public struct TrackingPermission: PermissionProviding {
    private let provider: any PermissionProviding

    public init(provider: any PermissionProviding) {
        self.provider = provider
    }

    public var status: PermissionStatus {
        get async { await provider.status }
    }

    public func requestAuthorization() async throws -> PermissionStatus {
        try await provider.requestAuthorization()
    }

    public func statusUpdates() -> AsyncStream<PermissionStatus> {
        provider.statusUpdates()
    }
}
