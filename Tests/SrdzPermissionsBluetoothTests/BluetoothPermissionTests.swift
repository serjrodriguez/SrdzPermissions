//
//  BluetoothPermissionTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsBluetooth
import SrdzPermissionsCore
import SrdzPermissionsTesting
import Testing

@Suite struct BluetoothPermissionTests {
    private static let ready = BluetoothStatus(permission: .authorized, radio: .poweredOn)

    @Test func requestAuthorizationReturnsTheScriptedResult() async throws {
        let provider = FakeBluetoothProvider(authorizationResult: Self.ready)
        let permission = BluetoothPermission(provider: provider)

        #expect(try await permission.requestAuthorization() == Self.ready)
        #expect(await provider.requestCount == 1)
    }

    @Test func statusReflectsTheProvider() async {
        let denied = BluetoothStatus(permission: .denied, radio: .unauthorized)
        let permission = BluetoothPermission(provider: FakeBluetoothProvider(status: denied))

        #expect(await permission.status == denied)
    }

    @Test func requestPropagatesTheScriptedError() async {
        let provider = FakeBluetoothProvider(authorizationError: .missingUsageDescription(key: "NSKey"))
        let permission = BluetoothPermission(provider: provider)

        await #expect(throws: PermissionError.missingUsageDescription(key: "NSKey")) {
            try await permission.requestAuthorization()
        }
    }

    @Test func statusUpdatesEmitTheInitialStatusAndChanges() async {
        let off = BluetoothStatus(permission: .authorized, radio: .poweredOff)
        let provider = FakeBluetoothProvider(status: .notDetermined, statusChanges: [Self.ready, off])
        let permission = BluetoothPermission(provider: provider)

        var seen: [BluetoothStatus] = []
        for await status in permission.statusUpdates() {
            seen.append(status)
        }

        #expect(seen == [.notDetermined, Self.ready, off])
    }
}
