//
//  BiometricsPermission+Live.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
extension BiometricsPermission {
    public static let live = BiometricsPermission(
        provider: BiometricsService(backend: LocalAuthenticationBackend())
    )
}
#endif
