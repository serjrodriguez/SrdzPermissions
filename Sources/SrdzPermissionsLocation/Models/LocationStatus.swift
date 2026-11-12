//
//  LocationStatus.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import SrdzPermissionsCore

/// How precisely the user allows the app to see their location.
public enum LocationPrecision: Sendable, Equatable, Hashable {
    /// Full, precise location.
    case full
    /// Approximate location only. The permission is reported as ``PermissionStatus/limited``.
    case reduced
}

/// The location authorization state: the permission, the access level granted and the precision.
public struct LocationStatus: Sendable, Equatable, Hashable {
    /// The authorization status. Reduced precision is reported as ``PermissionStatus/limited``.
    public var permission: PermissionStatus

    /// The access level the user granted, or `nil` when none.
    public var access: LocationAccess?
    /// The precision the user allows.
    public var precision: LocationPrecision

    /// Creates a status.
    ///
    /// - Parameters:
    ///   - permission: The authorization status.
    ///   - access: The access level granted, if any.
    ///   - precision: The precision allowed.
    public init(
        permission: PermissionStatus,
        access: LocationAccess? = nil,
        precision: LocationPrecision = .full
    ) {
        self.permission = permission
        self.access = access
        self.precision = precision
    }

    /// The user has not been asked yet.
    public static let notDetermined = LocationStatus(permission: .notDetermined)
}
