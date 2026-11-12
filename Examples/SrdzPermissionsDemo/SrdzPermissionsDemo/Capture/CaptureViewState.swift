//
//  CaptureViewState.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SrdzPermissions

struct CapturePermissionViewState: Equatable {
    let title: String
    var status = String(describing: PermissionStatus.notDetermined)
    var canOpenSettings = false
    var errorMessage: String?

    init(title: String) {
        self.title = title
    }

    mutating func apply(_ status: PermissionStatus) {
        self.status = String(describing: status)
        canOpenSettings = status == .denied
    }
}
