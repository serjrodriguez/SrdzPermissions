//
//  LocalAuthenticationBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
import Foundation
import LocalAuthentication
import SrdzPermissionsCore

struct LocalAuthenticationBackend: BiometricsBackend {
    func currentStatus() -> BiometricStatus {
        let context = LAContext()
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        let type = BiometricType(context.biometryType)

        guard !canEvaluate else {
            return BiometricStatus(type: type, availability: .available)
        }
        return BiometricStatus(type: type, availability: BiometricAvailability(laError: error))
    }

    func evaluate(reason: String) async throws -> BiometricResult {
        nonisolated(unsafe) let context = LAContext()
        return try await withTaskCancellationHandler {
            do {
                let success = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
                return success ? .success : .failed
            } catch let error as LAError {
                switch error.code {
                case .userCancel, .systemCancel, .appCancel:
                    try Task.checkCancellation()
                    return .cancelled
                case .userFallback:
                    return .fallbackRequested
                case .authenticationFailed:
                    return .failed
                case .biometryNotAvailable, .biometryNotEnrolled, .biometryLockout, .passcodeNotSet:
                    throw PermissionError.unavailable(reason: error.localizedDescription)
                default:
                    throw PermissionError.underlying(description: error.localizedDescription)
                }
            }
        } onCancel: {
            context.invalidate()
        }
    }
}

private extension BiometricType {
    init(_ type: LABiometryType) {
        switch type {
        case .touchID: self = .touchID
        case .faceID: self = .faceID
        default: self = type.rawValue == 4 ? .opticID : .none
        }
    }
}

private extension BiometricAvailability {
    init(laError error: NSError?) {
        guard let error, error.domain == LAError.errorDomain, let code = LAError.Code(rawValue: error.code) else {
            self = .notAvailable
            return
        }
        switch code {
        case .biometryNotEnrolled: self = .notEnrolled
        case .biometryLockout: self = .lockedOut
        case .passcodeNotSet: self = .passcodeNotSet
        default: self = .notAvailable
        }
    }
}
#endif
