//
//  TrackingPermissionTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore
import SrdzPermissionsTesting
import SrdzPermissionsTracking
import Testing

@Suite struct TrackingPermissionTests {
    @Test func requestAuthorizationReturnsTheScriptedResult() async throws {
        let provider = FakePermissionProvider(authorizationResult: .authorized)
        let permission = TrackingPermission(provider: provider)

        #expect(try await permission.requestAuthorization() == .authorized)
        #expect(await provider.requestCount == 1)
    }

    @Test func statusReflectsTheProvider() async {
        let permission = TrackingPermission(provider: FakePermissionProvider(status: .restricted))

        #expect(await permission.status == .restricted)
    }

    @Test func statusUpdatesEmitTheInitialStatusAndChanges() async {
        let provider = FakePermissionProvider(status: .notDetermined, statusChanges: [.authorized])
        let permission = TrackingPermission(provider: provider)

        var seen: [PermissionStatus] = []
        for await status in permission.statusUpdates() {
            seen.append(status)
        }

        #expect(seen == [.notDetermined, .authorized])
    }
}
