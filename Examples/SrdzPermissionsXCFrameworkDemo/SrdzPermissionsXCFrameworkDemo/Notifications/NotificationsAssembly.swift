//
//  NotificationsAssembly.swift
//  SrdzPermissionsXCFrameworkDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissions

enum NotificationsAssembly {
    @MainActor
    static func makeViewModel() -> NotificationsViewModel {
        NotificationsViewModel(permission: Permissions.notifications)
    }
}
