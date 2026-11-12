//
//  BiometricsPermission+Live.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
extension BiometricsPermission {
    /// The real implementation, backed by LocalAuthentication.
    public static let live = BiometricsPermission(
        provider: BiometricsService(backend: LocalAuthenticationBackend())
    )
}
#endif
