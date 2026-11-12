//
//  FakeBiometricsProvider.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsBiometrics
import SrdzPermissionsCore

/// A scripted ``BiometricsProviding`` for tests. Wrap it in a ``BiometricsPermission`` to inject it.
public actor FakeBiometricsProvider: BiometricsProviding {
    /// The scripted biometric status.
    public private(set) var status: BiometricStatus
    /// The reason of every authentication so far, in order.
    public private(set) var authenticationReasons: [String] = []

    private let result: BiometricResult

    /// Creates a fake.
    ///
    /// - Parameters:
    ///   - status: The scripted biometric status.
    ///   - result: The result returned by ``authenticate(reason:)`` when biometrics are available.
    public init(
        status: BiometricStatus = BiometricStatus(type: .faceID, availability: .available),
        result: BiometricResult = .success
    ) {
        self.status = status
        self.result = result
    }

    /// Records the reason and returns the scripted result, or throws ``PermissionError/unavailable(reason:)`` when biometrics are not available.
    public func authenticate(reason: String) async throws -> BiometricResult {
        authenticationReasons.append(reason)
        guard status.isAvailable else {
            throw PermissionError.unavailable(reason: "Biometrics are not available.")
        }
        return result
    }
}
