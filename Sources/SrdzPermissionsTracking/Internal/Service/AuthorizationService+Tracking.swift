//
//  AuthorizationService+Tracking.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

extension AuthorizationService where Scope == Unscoped {
    typealias TrackingUsageValidator = @Sendable () throws -> Void

    static let validateTrackingMainBundle: TrackingUsageValidator = {
        try InfoPlistValidator.require("NSUserTrackingUsageDescription")
    }

    static func makeTrackingService(
        backend: any TrackingBackend,
        validateUsageDescription: @escaping TrackingUsageValidator = validateTrackingMainBundle
    ) -> AuthorizationService<Unscoped> {
        AuthorizationService(
            readStatus: { _ in backend.currentStatus() },
            performRequest: { _ in await backend.requestAccess() },
            changeSignals: { backend.statusChanges() },
            validate: { _ in try validateUsageDescription() }
        )
    }
}
