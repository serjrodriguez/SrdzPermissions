//
//  LocationPermissionTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation
import Testing
@testable import SrdzPermissionsLocation
import SrdzPermissionsTesting

@Suite struct LocationPermissionTests {
    @Test func requestAuthorizationDefaultsToWhenInUse() async throws {
        let provider = FakeLocationProvider(authorizationResult: .whenInUse)
        let permission = LocationPermission(provider: provider)

        let status = try await permission.requestAuthorization()

        #expect(status == .whenInUse)
        #expect(await provider.requestedAccess == [.whenInUse])
    }

    @Test func statusReflectsTheProvider() async {
        let permission = LocationPermission(provider: FakeLocationProvider(status: .denied))

        #expect(await permission.status == .denied)
    }

    @Test func updatesStreamTheScriptedLocations() async throws {
        let first = Location(latitude: 1, longitude: 1)
        let second = Location(latitude: 2, longitude: 2)
        let permission = LocationPermission(provider: FakeLocationProvider(status: .whenInUse, locations: [first, second]))

        var received: [Location] = []
        for try await location in permission.updates() {
            received.append(location)
        }

        #expect(received == [first, second])
    }

    @Test func updatesFinishWithTheScriptedError() async {
        let provider = FakeLocationProvider(updatesError: .notAuthorized(.denied))
        let permission = LocationPermission(provider: provider)

        await #expect(throws: PermissionError.notAuthorized(.denied)) {
            for try await _ in permission.updates() {}
        }
    }

    @Test func statusUpdatesEmitTheInitialStatusAndChanges() async {
        let provider = FakeLocationProvider(status: .notDetermined, statusChanges: [.whenInUse, .denied])
        let permission = LocationPermission(provider: provider)

        var seen: [LocationStatus] = []
        for await status in permission.statusUpdates() {
            seen.append(status)
        }

        #expect(seen == [.notDetermined, .whenInUse, .denied])
    }

    @Test func currentLocationRequiresPermission() async {
        let provider = FakeLocationProvider(status: .denied, currentLocation: .success(Location(latitude: 0, longitude: 0)))
        let permission = LocationPermission(provider: provider)

        await #expect(throws: PermissionError.notAuthorized(.denied)) {
            try await permission.currentLocation()
        }
    }

    @Test func currentLocationReturnsTheScriptedFix() async throws {
        let fix = Location(latitude: 19.43, longitude: -99.13)
        let provider = FakeLocationProvider(status: .whenInUse, currentLocation: .success(fix))
        let permission = LocationPermission(provider: provider)

        #expect(try await permission.currentLocation() == fix)
    }
}
