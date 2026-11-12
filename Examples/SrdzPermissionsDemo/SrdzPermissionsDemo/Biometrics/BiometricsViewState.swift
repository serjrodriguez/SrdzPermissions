//
//  BiometricsViewState.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissions

struct BiometricsViewState: Equatable {
    var type = String(describing: BiometricType.none)
    var availability = String(describing: BiometricAvailability.notAvailable)
    var isAvailable = false
    var lastResult: String?
    var isAuthenticating = false
    var errorMessage: String?

    mutating func apply(_ status: BiometricStatus) {
        type = String(describing: status.type)
        availability = String(describing: status.availability)
        isAvailable = status.isAvailable
    }
}
