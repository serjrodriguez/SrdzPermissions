//
//  BluetoothStatus.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

public enum BluetoothRadioState: Sendable, Equatable, Hashable {
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn
}

public struct BluetoothStatus: Sendable, Equatable, Hashable {
    public var permission: PermissionStatus
    public var radio: BluetoothRadioState

    public init(permission: PermissionStatus, radio: BluetoothRadioState = .unknown) {
        self.permission = permission
        self.radio = radio
    }

    public var isReady: Bool {
        permission.isGranted && radio == .poweredOn
    }

    public static let notDetermined = BluetoothStatus(permission: .notDetermined)
}
