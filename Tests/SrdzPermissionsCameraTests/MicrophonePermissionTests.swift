//
//  MicrophonePermissionTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SrdzPermissionsCore
import Testing
import SrdzPermissionsCamera
import SrdzPermissionsTesting

@Suite struct MicrophonePermissionTests {
    @Test func requestAuthorizationReturnsTheScriptedResult() async throws {
        let provider = FakeCapturePermissionProvider(authorizationResult: .authorized)
        let permission = MicrophonePermission(provider: provider)

        let status = try await permission.requestAuthorization()

        #expect(status == .authorized)
        #expect(await provider.requestCount == 1)
    }

    @Test func statusReflectsTheProvider() async {
        let permission = MicrophonePermission(provider: FakeCapturePermissionProvider(status: .restricted))

        #expect(await permission.status == .restricted)
    }

    @Test func deniedStaysDeniedAfterARequest() async throws {
        let provider = FakeCapturePermissionProvider(status: .denied, authorizationResult: .authorized)
        let permission = MicrophonePermission(provider: provider)

        #expect(try await permission.requestAuthorization() == .denied)
    }

    @Test func requestPropagatesTheScriptedError() async {
        let provider = FakeCapturePermissionProvider(authorizationError: .missingUsageDescription(key: "NSKey"))
        let permission = MicrophonePermission(provider: provider)

        await #expect(throws: PermissionError.missingUsageDescription(key: "NSKey")) {
            try await permission.requestAuthorization()
        }
    }

    @Test func statusUpdatesEmitTheInitialStatusAndChanges() async {
        let provider = FakeCapturePermissionProvider(status: .notDetermined, statusChanges: [.authorized, .denied])
        let permission = MicrophonePermission(provider: provider)

        var seen: [PermissionStatus] = []
        for await status in permission.statusUpdates() {
            seen.append(status)
        }

        #expect(seen == [.notDetermined, .authorized, .denied])
    }
}
