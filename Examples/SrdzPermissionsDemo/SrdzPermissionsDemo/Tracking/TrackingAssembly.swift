//
//  TrackingAssembly.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissions

enum TrackingAssembly {
    @MainActor
    static func makeViewModel() -> PermissionViewModel {
        PermissionViewModel(title: "App Tracking Transparency", permission: Permissions.tracking)
    }
}
