//
//  BluetoothStatusTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore
import Testing
@testable import SrdzPermissionsBluetooth

@Suite struct BluetoothStatusTests {
    @Test func isReadyNeedsPermissionAndAPoweredOnRadio() {
        #expect(BluetoothStatus(permission: .authorized, radio: .poweredOn).isReady)
        #expect(!BluetoothStatus(permission: .authorized, radio: .poweredOff).isReady)
        #expect(!BluetoothStatus(permission: .denied, radio: .poweredOn).isReady)
        #expect(!BluetoothStatus.notDetermined.isReady)
    }

    @Test func notDeterminedHasAnUnknownRadio() {
        #expect(BluetoothStatus.notDetermined == BluetoothStatus(permission: .notDetermined, radio: .unknown))
    }
}
