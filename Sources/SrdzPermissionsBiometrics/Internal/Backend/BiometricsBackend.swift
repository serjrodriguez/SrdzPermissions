//
//  BiometricsBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

protocol BiometricsBackend: Sendable {
    func currentStatus() -> BiometricStatus
    func evaluate(reason: String) async throws -> BiometricResult
}
