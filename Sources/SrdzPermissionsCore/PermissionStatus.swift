//
//  PermissionStatus.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

/// The state of a permission as reported by the system.
public enum PermissionStatus: Sendable, Equatable, Hashable {
    /// The user has not been asked yet.
    case notDetermined
    /// The user granted full access.
    case authorized
    /// The user granted partial access, such as a selection of photos, reduced location precision or provisional notifications.
    case limited
    /// The user refused access. iOS does not prompt again, so direct the user to Settings with ``AppSettings/open()``.
    case denied
    /// A system policy such as parental controls prevents access, and the user cannot change it.
    case restricted

    /// `true` for ``authorized`` and ``limited``, the states in which the app can use the feature.
    public var isGranted: Bool {
        self == .authorized || self == .limited
    }
}
