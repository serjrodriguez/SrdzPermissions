//
//  LocationAssembly.swift
//  SrdzPermissionsXCFrameworkDemo
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SrdzPermissions

enum LocationAssembly {
    @MainActor
    static func makeViewModel() -> LocationViewModel {
        LocationViewModel(permission: Permissions.location)
    }
}
