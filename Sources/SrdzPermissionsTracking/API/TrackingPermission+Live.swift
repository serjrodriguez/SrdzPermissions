//
//  TrackingPermission+Live.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
import SrdzPermissionsCore

extension TrackingPermission {
    /// The real implementation, backed by AppTrackingTransparency.
    public static let live = TrackingPermission(
        provider: AuthorizationService<Unscoped>.makeTrackingService(backend: AppTrackingBackend())
    )
}
#endif
