//
//  FakeBiometricsProvider.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsBiometrics
import SrdzPermissionsCore

public actor FakeBiometricsProvider: BiometricsProviding {
    public private(set) var status: BiometricStatus
    public private(set) var authenticationReasons: [String] = []

    private let result: BiometricResult

    public init(
        status: BiometricStatus = BiometricStatus(type: .faceID, availability: .available),
        result: BiometricResult = .success
    ) {
        self.status = status
        self.result = result
    }

    public func authenticate(reason: String) async throws -> BiometricResult {
        authenticationReasons.append(reason)
        guard status.isAvailable else {
            throw PermissionError.unavailable(reason: "Biometrics are not available.")
        }
        return result
    }
}
