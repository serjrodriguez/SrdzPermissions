//
//  PermissionError.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation

public enum PermissionError: Error, Sendable, Equatable {
    case notAuthorized(PermissionStatus)
    case missingUsageDescription(key: String)
    case servicesDisabled
    case timeout
    case unavailable(reason: String)
    case underlying(description: String)
}

extension PermissionError: LocalizedError {
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
