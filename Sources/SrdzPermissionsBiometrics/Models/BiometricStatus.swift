//
//  BiometricStatus.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

public enum BiometricType: Sendable, Equatable, Hashable {
    case none
    case touchID
    case faceID
    case opticID
}

public enum BiometricAvailability: Sendable, Equatable, Hashable {
    case available
    case notEnrolled
    case lockedOut
    case passcodeNotSet
    case notAvailable
}

public struct BiometricStatus: Sendable, Equatable, Hashable {
    public var type: BiometricType
    public var availability: BiometricAvailability

    public init(type: BiometricType, availability: BiometricAvailability) {
        self.type = type
        self.availability = availability
    }

    public var isAvailable: Bool {
        availability == .available
    }

    public static let unavailable = BiometricStatus(type: .none, availability: .notAvailable)
}

public enum BiometricResult: Sendable, Equatable, Hashable {
    case success
    case cancelled
    case fallbackRequested
    case failed
}
