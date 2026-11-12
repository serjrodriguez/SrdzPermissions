//
//  BluetoothViewState.swift
//  SrdzPermissionsXCFrameworkDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissions

struct BluetoothViewState: Equatable {
    var permission = String(describing: PermissionStatus.notDetermined)
    var radio = String(describing: BluetoothRadioState.unknown)
    var isReady = false
    var canOpenSettings = false
    var errorMessage: String?

    mutating func apply(_ status: BluetoothStatus) {
        permission = String(describing: status.permission)
        radio = String(describing: status.radio)
        isReady = status.isReady
        canOpenSettings = status.permission == .denied
    }
}
