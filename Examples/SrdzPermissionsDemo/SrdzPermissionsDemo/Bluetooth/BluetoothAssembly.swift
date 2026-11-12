//
//  BluetoothAssembly.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissions

enum BluetoothAssembly {
    @MainActor
    static func makeViewModel() -> BluetoothViewModel {
        BluetoothViewModel(permission: Permissions.bluetooth)
    }
}
