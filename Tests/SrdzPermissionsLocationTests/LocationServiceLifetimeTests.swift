//
//  LocationServiceLifetimeTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import Testing
@testable import SrdzPermissionsLocation

@Suite struct LocationServiceLifetimeTests {
    @Test func theBackendIsReleasedWhenTheServiceIsReleased() async {
        weak var weakBackend: FakeLocationBackend?
        do {
            let backend = FakeLocationBackend(status: .whenInUse)
            weakBackend = backend
            let service = LocationService(makeBackend: { backend }, validateUsageDescriptions: { _ in })

            _ = await service.status
            let updates = Task {
                for try await _ in service.updates(options: LocationUpdateOptions()) {}
            }
            let statuses = Task {
                for await _ in service.statusUpdates() {}
            }
            await waitUntil { await service.subscribers.count == 1 }
            updates.cancel()
            statuses.cancel()
            _ = try? await updates.value
            await statuses.value
        }

        for _ in 0..<10_000 where weakBackend != nil {
            await Task.yield()
        }
        #expect(weakBackend == nil)
    }

    @Test func abandonedStreamsDoNotKeepTheServiceAlive() async {
        weak var weakService: LocationService?
        do {
            let backend = FakeLocationBackend(status: .whenInUse)
            let service = LocationService(makeBackend: { backend }, validateUsageDescriptions: { _ in })
            weakService = service

            _ = await service.status
            _ = service.updates(options: LocationUpdateOptions())
            _ = service.statusUpdates()
        }

        for _ in 0..<10_000 where weakService != nil {
            await Task.yield()
        }
        #expect(weakService == nil)
    }
}
