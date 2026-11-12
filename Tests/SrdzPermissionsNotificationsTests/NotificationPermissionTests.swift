//
//  NotificationPermissionTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore
import SrdzPermissionsNotifications
import SrdzPermissionsTesting
import Testing

@Suite struct NotificationPermissionTests {
    @Test func requestUsesTheStandardOptionsByDefault() async throws {
        let provider = FakeNotificationProvider(authorizationResult: .authorized)
        let permission = NotificationPermission(provider: provider)

        let status = try await permission.requestAuthorization()

        #expect(status == .authorized)
        #expect(await provider.requestedOptions == [.standard])
    }

    @Test func requestForwardsCustomOptions() async throws {
        let provider = FakeNotificationProvider(authorizationResult: .limited)
        let permission = NotificationPermission(provider: provider)

        _ = try await permission.requestAuthorization(options: [.alert, .provisional])

        #expect(await provider.requestedOptions == [[.alert, .provisional]])
    }

    @Test func statusReflectsTheProvider() async {
        let permission = NotificationPermission(provider: FakeNotificationProvider(status: .denied))

        #expect(await permission.status == .denied)
    }

    @Test func requestPropagatesTheScriptedError() async {
        let provider = FakeNotificationProvider(authorizationError: .unavailable(reason: "no bundle"))
        let permission = NotificationPermission(provider: provider)

        await #expect(throws: PermissionError.unavailable(reason: "no bundle")) {
            try await permission.requestAuthorization()
        }
    }

    @Test func statusUpdatesEmitTheInitialStatusAndChanges() async {
        let provider = FakeNotificationProvider(status: .notDetermined, statusChanges: [.authorized, .denied])
        let permission = NotificationPermission(provider: provider)

        var seen: [PermissionStatus] = []
        for await status in permission.statusUpdates() {
            seen.append(status)
        }

        #expect(seen == [.notDetermined, .authorized, .denied])
    }
}
