//
//  BiometricsProviding.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

/// A source of biometric status and authentication. ``BiometricsPermission`` is the facade apps use; conform to this protocol to provide a fake.
public protocol BiometricsProviding: Sendable {
    /// The biometric capabilities and their availability.
    var status: BiometricStatus { get async }

    /// Asks the user to authenticate with biometrics.
    ///
    /// - Parameter reason: A message shown to the user explaining why.
    /// - Returns: The outcome of the attempt.
    /// - Throws: ``PermissionError/unavailable(reason:)`` if biometrics cannot be used, or `CancellationError` if the task is cancelled.
    func authenticate(reason: String) async throws -> BiometricResult
}
