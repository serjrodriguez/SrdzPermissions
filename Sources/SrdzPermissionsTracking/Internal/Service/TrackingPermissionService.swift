//
//  TrackingPermissionService.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

struct TrackingPermissionService: PermissionProviding {
    typealias UsageValidator = @Sendable () throws -> Void

    private let core: AuthorizationService<Unscoped>
    private let validateUsageDescription: UsageValidator

    init(
        backend: any TrackingBackend,
        validateUsageDescription: @escaping UsageValidator = TrackingPermissionService.validateMainBundle
    ) {
        self.core = AuthorizationService(
            readStatus: { _ in backend.currentStatus() },
            performRequest: { _ in await backend.requestAccess() },
            changeSignals: { backend.statusChanges() }
        )
        self.validateUsageDescription = validateUsageDescription
    }

    static let validateMainBundle: UsageValidator = {
        try InfoPlistValidator.require("NSUserTrackingUsageDescription")
    }

    var status: PermissionStatus {
        get async { await core.status(for: Unscoped()) }
    }

    func requestAuthorization() async throws -> PermissionStatus {
        try validateUsageDescription()
        return try await core.requestAuthorization(for: Unscoped())
    }

    func statusUpdates() -> AsyncStream<PermissionStatus> {
        core.statusUpdates(for: Unscoped())
    }
}
