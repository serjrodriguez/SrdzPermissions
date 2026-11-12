//
//  CapturePermissionService.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import SrdzPermissionsCore

struct CapturePermissionService: PermissionProviding {
    typealias UsageValidator = @Sendable (String) throws -> Void

    private let core: AuthorizationService<Unscoped>
    private let usageDescriptionKey: String
    private let validateUsageDescription: UsageValidator

    init(
        backend: any CaptureBackend,
        usageDescriptionKey: String,
        validateUsageDescription: @escaping UsageValidator = CapturePermissionService.validateMainBundle
    ) {
        self.core = AuthorizationService(
            readStatus: { _ in backend.currentStatus() },
            performRequest: { _ in _ = await backend.requestAccess() },
            changeSignals: { backend.statusChanges() }
        )
        self.usageDescriptionKey = usageDescriptionKey
        self.validateUsageDescription = validateUsageDescription
    }

    static let validateMainBundle: UsageValidator = { key in
        try InfoPlistValidator.require(key)
    }

    var status: PermissionStatus {
        get async { await core.status(for: Unscoped()) }
    }

    func requestAuthorization() async throws -> PermissionStatus {
        try validateUsageDescription(usageDescriptionKey)
        return try await core.requestAuthorization(for: Unscoped())
    }

    func statusUpdates() -> AsyncStream<PermissionStatus> {
        core.statusUpdates(for: Unscoped())
    }
}
