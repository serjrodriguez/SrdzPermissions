//
//  BiometricStatus.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

/// The kind of biometric authentication the device offers.
public enum BiometricType: Sendable, Equatable, Hashable {
    /// The device offers no biometric authentication.
    case none
    /// Touch ID.
    case touchID
    /// Face ID.
    case faceID
    /// Optic ID.
    case opticID
}

/// Whether biometric authentication can be used right now.
public enum BiometricAvailability: Sendable, Equatable, Hashable {
    /// Biometric authentication can be used.
    case available
    /// The device has no enrolled face or fingerprint.
    case notEnrolled
    /// Biometrics are locked after too many failed attempts.
    case lockedOut
    /// The device has no passcode, which biometrics require.
    case passcodeNotSet
    /// Biometrics are unavailable. This is also what iOS reports when the user denied Face ID for the app.
    case notAvailable
}

/// The biometric capabilities of the device and whether they can be used.
public struct BiometricStatus: Sendable, Equatable, Hashable {
    /// The kind of biometric authentication the device offers.
    public var type: BiometricType
    /// Whether biometric authentication can be used right now.
    public var availability: BiometricAvailability

    /// Creates a status.
    ///
    /// - Parameters:
    ///   - type: The kind of biometric authentication.
    ///   - availability: Whether it can be used.
    public init(type: BiometricType, availability: BiometricAvailability) {
        self.type = type
        self.availability = availability
    }

    /// `true` when ``availability`` is ``BiometricAvailability/available``.
    public var isAvailable: Bool {
        availability == .available
    }

    /// No biometric authentication is available.
    public static let unavailable = BiometricStatus(type: .none, availability: .notAvailable)
}

/// The outcome of an authentication attempt.
public enum BiometricResult: Sendable, Equatable, Hashable {
    /// The user was recognized.
    case success
    /// The user or the system cancelled the attempt.
    case cancelled
    /// The user chose to enter a passcode instead.
    case fallbackRequested
    /// The user was not recognized.
    case failed
}
