//
//  BiometricsPermission.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

/// Checks and uses Face ID, Touch ID and Optic ID.
///
/// Use `Permissions.biometrics` for the real implementation. Unlike the other permissions, iOS offers no way to ask for Face ID or to read its status: the system prompt appears the first time you authenticate. So this type reports availability instead of a ``PermissionStatus``. Requires `NSFaceIDUsageDescription` on devices with Face ID.
public struct BiometricsPermission: BiometricsProviding {
    private let provider: any BiometricsProviding

    /// Creates a permission backed by `provider`.
    ///
    /// - Parameter provider: The implementation that answers the calls, usually ``live``.
    public init(provider: any BiometricsProviding) {
        self.provider = provider
    }

    /// The biometric capabilities and their availability.
    public var status: BiometricStatus {
        get async { await provider.status }
    }

    /// Asks the user to authenticate with biometrics.
    ///
    /// Cancelling the task dismisses the system prompt and throws `CancellationError`.
    ///
    /// - Parameter reason: A message shown to the user explaining why.
    /// - Returns: The outcome of the attempt.
    /// - Throws: ``PermissionError/unavailable(reason:)`` if biometrics cannot be used, ``PermissionError/missingUsageDescription(key:)`` if `NSFaceIDUsageDescription` is missing on a Face ID device, or `CancellationError` if the task is cancelled.
    public func authenticate(reason: String) async throws -> BiometricResult {
        try await provider.authenticate(reason: reason)
    }
}
