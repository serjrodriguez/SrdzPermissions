//
//  LocationStatus.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import SrdzPermissionsCore

public enum LocationPrecision: Sendable, Equatable, Hashable {
    case full
    case reduced
}

public struct LocationStatus: Sendable, Equatable, Hashable {
    public var permission: PermissionStatus

    public var access: LocationAccess?
    public var precision: LocationPrecision

    public init(
        permission: PermissionStatus,
        access: LocationAccess? = nil,
        precision: LocationPrecision = .full
    ) {
        self.permission = permission
        self.access = access
        self.precision = precision
    }

    public static let notDetermined = LocationStatus(permission: .notDetermined)
}
