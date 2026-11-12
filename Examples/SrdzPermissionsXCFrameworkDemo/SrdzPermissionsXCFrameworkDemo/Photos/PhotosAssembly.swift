//
//  PhotosAssembly.swift
//  SrdzPermissionsXCFrameworkDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissions

enum PhotosAssembly {
    @MainActor
    static func makeViewModel() -> PhotosViewModel {
        PhotosViewModel(permission: Permissions.photos)
    }
}
