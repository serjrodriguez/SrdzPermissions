//
//  BiometricsProviding.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

public protocol BiometricsProviding: Sendable {
    var status: BiometricStatus { get async }

    func authenticate(reason: String) async throws -> BiometricResult
}
