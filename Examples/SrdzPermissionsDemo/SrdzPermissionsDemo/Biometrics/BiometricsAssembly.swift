//
//  BiometricsAssembly.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissions

enum BiometricsAssembly {
    @MainActor
    static func makeViewModel() -> BiometricsViewModel {
        BiometricsViewModel(permission: Permissions.biometrics)
    }
}
