//
//  BiometricsService.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

struct BiometricsService: BiometricsProviding {
    typealias UsageValidator = @Sendable () throws -> Void

    private let backend: any BiometricsBackend
    private let validateFaceIDUsageDescription: UsageValidator

    init(
        backend: any BiometricsBackend,
        validateFaceIDUsageDescription: @escaping UsageValidator = BiometricsService.validateMainBundle
    ) {
        self.backend = backend
        self.validateFaceIDUsageDescription = validateFaceIDUsageDescription
    }

    static let validateMainBundle: UsageValidator = {
        try InfoPlistValidator.require("NSFaceIDUsageDescription")
    }

    var status: BiometricStatus {
        get async { backend.currentStatus() }
    }

    func authenticate(reason: String) async throws -> BiometricResult {
        let status = backend.currentStatus()
        if status.type == .faceID {
            try validateFaceIDUsageDescription()
        }
        guard status.isAvailable else {
            throw PermissionError.unavailable(reason: status.availability.explanation)
        }
        return try await backend.evaluate(reason: reason)
    }
}

private extension BiometricAvailability {
    var explanation: String {
        switch self {
        case .available: "Biometric authentication is available."
        case .notEnrolled: "No biometric identity is enrolled on this device."
        case .lockedOut: "Biometric authentication is locked after too many failed attempts."
        case .passcodeNotSet: "The device has no passcode."
        case .notAvailable: "Biometric authentication is not available. This can also mean the user denied Face ID for this app."
        }
    }
}
