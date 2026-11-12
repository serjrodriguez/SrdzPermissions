//
//  BiometricsPermission.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

public struct BiometricsPermission: BiometricsProviding {
    private let provider: any BiometricsProviding

    public init(provider: any BiometricsProviding) {
        self.provider = provider
    }

    public var status: BiometricStatus {
        get async { await provider.status }
    }

    public func authenticate(reason: String) async throws -> BiometricResult {
        try await provider.authenticate(reason: reason)
    }
}
