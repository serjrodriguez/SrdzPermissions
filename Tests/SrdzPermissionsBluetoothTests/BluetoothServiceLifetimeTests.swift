//
//  BluetoothServiceLifetimeTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import Testing
@testable import SrdzPermissionsBluetooth

@Suite struct BluetoothServiceLifetimeTests {
    @Test func theBackendIsReleasedWhenTheServiceIsReleased() async {
        weak var weakBackend: FakeBluetoothBackend?
        do {
            let backend = FakeBluetoothBackend(status: .ready)
            weakBackend = backend
            let service = BluetoothService(makeBackend: { backend }, validateUsageDescription: {})

            let statuses = Task {
                for await _ in service.statusUpdates() {}
            }
            await waitUntil { await service.subscribers.count == 1 }
            statuses.cancel()
            await statuses.value
        }

        for _ in 0..<10_000 where weakBackend != nil {
            await Task.yield()
        }
        #expect(weakBackend == nil)
    }

    @Test func aPendingRequestIsReleasedAfterCancellation() async {
        weak var weakBackend: FakeBluetoothBackend?
        do {
            let backend = FakeBluetoothBackend()
            weakBackend = backend
            let service = BluetoothService(makeBackend: { backend }, validateUsageDescription: {})

            let request = Task { try await service.requestAuthorization() }
            await waitUntil { await backend.startCount >= 1 }
            request.cancel()
            _ = try? await request.value
        }

        for _ in 0..<10_000 where weakBackend != nil {
            await Task.yield()
        }
        #expect(weakBackend == nil)
    }
}
