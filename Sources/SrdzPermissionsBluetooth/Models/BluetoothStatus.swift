//
//  BluetoothStatus.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

/// The state of the Bluetooth hardware, which is separate from the app's permission.
public enum BluetoothRadioState: Sendable, Equatable, Hashable {
    /// The state has not been reported yet.
    case unknown
    /// The connection with the system service was lost and is being restored.
    case resetting
    /// The device does not support Bluetooth Low Energy. This is the case on the simulator.
    case unsupported
    /// The app is not allowed to use Bluetooth.
    case unauthorized
    /// Bluetooth is turned off.
    case poweredOff
    /// Bluetooth is on and available.
    case poweredOn
}

/// The Bluetooth state: whether the app has permission and whether the radio is on.
public struct BluetoothStatus: Sendable, Equatable, Hashable {
    /// The app's authorization status.
    public var permission: PermissionStatus
    /// The state of the Bluetooth hardware.
    public var radio: BluetoothRadioState

    /// Creates a status.
    ///
    /// - Parameters:
    ///   - permission: The app's authorization status.
    ///   - radio: The state of the Bluetooth hardware.
    public init(permission: PermissionStatus, radio: BluetoothRadioState = .unknown) {
        self.permission = permission
        self.radio = radio
    }

    /// `true` when the app has permission and the radio is on.
    public var isReady: Bool {
        permission.isGranted && radio == .poweredOn
    }

    /// The user has not been asked yet and the radio state is unknown.
    public static let notDetermined = BluetoothStatus(permission: .notDetermined)
}
