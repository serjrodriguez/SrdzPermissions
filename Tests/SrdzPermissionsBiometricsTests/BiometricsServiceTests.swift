//
//  BiometricsServiceTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import SrdzPermissionsCore
import Testing
@testable import SrdzPermissionsBiometrics

private final class FakeBiometricsBackend: BiometricsBackend, @unchecked Sendable {
    private let lock = NSLock()
    private let status: BiometricStatus
    private let result: BiometricResult
    private var reasons: [String] = []

    init(status: BiometricStatus, result: BiometricResult = .success) {
        self.status = status
        self.result = result
    }

    var evaluations: [String] { lock.withLock { reasons } }

    func currentStatus() -> BiometricStatus { status }

    func evaluate(reason: String) async throws -> BiometricResult {
        lock.withLock { reasons.append(reason) }
        return result
    }
}

private let faceID = BiometricStatus(type: .faceID, availability: .available)
private let touchID = BiometricStatus(type: .touchID, availability: .available)

@Suite struct BiometricsServiceTests {
    @Test func statusReadsTheBackend() async {
        let service = BiometricsService(backend: FakeBiometricsBackend(status: touchID), validateFaceIDUsageDescription: {})

        #expect(await service.status == touchID)
    }

    @Test(arguments: [BiometricResult.success, .cancelled, .fallbackRequested, .failed])
    func theBackendResultIsReturned(result: BiometricResult) async throws {
        let backend = FakeBiometricsBackend(status: faceID, result: result)
        let service = BiometricsService(backend: backend, validateFaceIDUsageDescription: {})

        #expect(try await service.authenticate(reason: "Unlock") == result)
        #expect(backend.evaluations == ["Unlock"])
    }

    @Test func faceIDRequiresTheUsageDescriptionBeforeEvaluating() async {
        let backend = FakeBiometricsBackend(status: faceID)
        let service = BiometricsService(backend: backend) {
            throw PermissionError.missingUsageDescription(key: "NSFaceIDUsageDescription")
        }

        await #expect(throws: PermissionError.missingUsageDescription(key: "NSFaceIDUsageDescription")) {
            try await service.authenticate(reason: "Unlock")
        }
        #expect(backend.evaluations.isEmpty)
    }

    @Test func touchIDDoesNotNeedTheFaceIDUsageDescription() async throws {
        let backend = FakeBiometricsBackend(status: touchID)
        let service = BiometricsService(backend: backend) {
            throw PermissionError.missingUsageDescription(key: "NSFaceIDUsageDescription")
        }

        #expect(try await service.authenticate(reason: "Unlock") == .success)
    }

    @Test(arguments: [
        BiometricAvailability.notEnrolled,
        .lockedOut,
        .passcodeNotSet,
        .notAvailable,
    ])
    func anUnavailableBiometryThrowsWithoutEvaluating(availability: BiometricAvailability) async {
        let backend = FakeBiometricsBackend(status: BiometricStatus(type: .faceID, availability: availability))
        let service = BiometricsService(backend: backend, validateFaceIDUsageDescription: {})

        await #expect(throws: PermissionError.self) {
            try await service.authenticate(reason: "Unlock")
        }
        #expect(backend.evaluations.isEmpty)
    }

    @Test func eachUnavailabilityHasItsOwnExplanation() async {
        var reasons: Set<String> = []
        for availability in [BiometricAvailability.notEnrolled, .lockedOut, .passcodeNotSet, .notAvailable] {
            let service = BiometricsService(
                backend: FakeBiometricsBackend(status: BiometricStatus(type: .touchID, availability: availability)),
                validateFaceIDUsageDescription: {}
            )
            do {
                _ = try await service.authenticate(reason: "Unlock")
            } catch let PermissionError.unavailable(reason) {
                reasons.insert(reason)
            } catch {}
        }

        #expect(reasons.count == 4)
    }
}
