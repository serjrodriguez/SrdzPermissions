//
//  LocationPermission+Live.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

#if os(iOS)
extension LocationPermission {
    public static let live = LocationPermission(
        provider: LocationService(makeBackend: { await CoreLocationBackend() })
    )
}
#endif
