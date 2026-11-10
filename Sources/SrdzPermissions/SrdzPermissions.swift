//
//  SrdzPermissions.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

@_exported import SrdzPermissionsCore
@_exported import SrdzPermissionsLocation

public enum Permissions {
    #if os(iOS)
    public static var location: LocationPermission { .live }
    #endif
}
