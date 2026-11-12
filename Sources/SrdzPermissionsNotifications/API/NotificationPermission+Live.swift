//
//  NotificationPermission+Live.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
extension NotificationPermission {
    /// The real implementation, backed by UserNotifications.
    public static let live = NotificationPermission(
        provider: NotificationService(backend: UserNotificationsBackend())
    )
}
#endif
