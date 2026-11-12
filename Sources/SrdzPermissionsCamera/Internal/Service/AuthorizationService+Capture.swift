//
//  AuthorizationService+Capture.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

extension AuthorizationService where Scope == Unscoped {
    typealias UsageValidator = @Sendable (String) throws -> Void

    static let validateMainBundle: UsageValidator = { key in
        try InfoPlistValidator.require(key)
    }

    static func makeCaptureService(
        backend: any CaptureBackend,
        usageDescriptionKey: String,
        validateUsageDescription: @escaping UsageValidator = validateMainBundle
    ) -> AuthorizationService<Unscoped> {
        AuthorizationService(
            readStatus: { _ in backend.currentStatus() },
            performRequest: { _ in _ = await backend.requestAccess() },
            changeSignals: { backend.statusChanges() },
            validate: { _ in try validateUsageDescription(usageDescriptionKey) }
        )
    }
}
