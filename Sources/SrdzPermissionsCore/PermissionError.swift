//
//  PermissionError.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation

/// An error raised when a permission request, or an operation that needs a permission, cannot be completed.
///
/// Denying a permission is not an error: requests return a ``PermissionStatus`` instead.
public enum PermissionError: Error, Sendable, Equatable {
    /// The operation needs a permission the app does not have. The associated status says why.
    case notAuthorized(PermissionStatus)
    /// The app's Info.plist lacks a required usage description. Without it iOS would fail silently. `key` is the missing key.
    case missingUsageDescription(key: String)
    /// The system service the permission depends on is turned off, for example Location Services.
    case servicesDisabled
    /// The operation did not finish within the requested time.
    case timeout
    /// The feature cannot be used on this device or in its current state. `reason` explains why.
    case unavailable(reason: String)
    /// A framework error without a dedicated case, described by its localized description.
    case underlying(description: String)
}

extension PermissionError: LocalizedError {
    /// A human-readable description of the error.
    public var errorDescription: String? {
        switch self {
            case .notAuthorized(let status):
                "Permission not granted (status: \(status))."
            case .missingUsageDescription(let key):
                "Missing Info.plist key: \(key)."
            case .servicesDisabled:
                "The required system service is disabled."
            case .timeout:
                "The operation timed out."
            case .unavailable(let reason):
                "Unavailable: \(reason)"
            case .underlying(let description):
                description
        }
    }
}
