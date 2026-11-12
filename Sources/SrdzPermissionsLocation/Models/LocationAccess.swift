//
//  LocationAccess.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

/// The level of location access to ask for.
public enum LocationAccess: Sendable, Equatable, Hashable {
    /// Access while the app is in use. Needs `NSLocationWhenInUseUsageDescription`.
    case whenInUse
    /// Access in the background as well. Also needs `NSLocationAlwaysAndWhenInUseUsageDescription`.
    case always
}
