//
//  MicrophonePermission.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SrdzPermissionsCore

public struct MicrophonePermission: CapturePermissionProviding {
    private let provider: any CapturePermissionProviding

    public init(provider: any CapturePermissionProviding) {
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
