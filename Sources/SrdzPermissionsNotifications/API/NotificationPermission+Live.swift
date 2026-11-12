//
//  NotificationPermission+Live.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
extension NotificationPermission {
    public static let live = NotificationPermission(
        provider: NotificationService(backend: UserNotificationsBackend())
    )
}
#endif
