//
//  NotificationsViewState.swift
//  SrdzPermissionsXCFrameworkDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissions

struct NotificationsViewState: Equatable {
    var status = String(describing: PermissionStatus.notDetermined)
    var canOpenSettings = false
    var errorMessage: String?

    mutating func apply(_ status: PermissionStatus) {
        self.status = String(describing: status)
        canOpenSettings = status == .denied
    }
}
