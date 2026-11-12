//
//  TrackingPermission+Live.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
extension TrackingPermission {
    public static let live = TrackingPermission(
        provider: TrackingPermissionService(backend: AppTrackingBackend())
    )
}
#endif
