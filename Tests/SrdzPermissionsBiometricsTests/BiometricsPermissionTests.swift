//
//  BiometricsPermissionTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsBiometrics
import SrdzPermissionsCore
import SrdzPermissionsTesting
import Testing

@Suite struct BiometricsPermissionTests {
    @Test func statusReflectsTheProvider() async {
        let status = BiometricStatus(type: .touchID, availability: .notEnrolled)
        let permission = BiometricsPermission(provider: FakeBiometricsProvider(status: status))

        #expect(await permission.status == status)
        #expect(!status.isAvailable)
    }

    @Test func authenticateForwardsTheReasonAndReturnsTheResult() async throws {
        let provider = FakeBiometricsProvider(result: .cancelled)
        let permission = BiometricsPermission(provider: provider)

        #expect(try await permission.authenticate(reason: "Unlock") == .cancelled)
        #expect(await provider.authenticationReasons == ["Unlock"])
    }

    @Test func authenticateThrowsWhenBiometricsAreUnavailable() async {
        let provider = FakeBiometricsProvider(status: .unavailable)
        let permission = BiometricsPermission(provider: provider)

        await #expect(throws: PermissionError.self) {
            try await permission.authenticate(reason: "Unlock")
        }
    }
}
