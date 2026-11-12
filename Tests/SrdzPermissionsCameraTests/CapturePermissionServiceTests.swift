//
//  CapturePermissionServiceTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import Foundation
import SrdzPermissionsCore
import Testing
@testable import SrdzPermissionsCamera

@Suite struct CapturePermissionServiceTests {
    private func makeService(
        backend: FakeCaptureBackend,
        validator: @escaping AuthorizationService<Unscoped>.UsageValidator = { _ in }
    ) -> AuthorizationService<Unscoped> {
        AuthorizationService.makeCaptureService(
            backend: backend,
            usageDescriptionKey: "NSCameraUsageDescription",
            validateUsageDescription: validator
        )
    }

    @Test func statusReadsTheBackend() async {
        let service = makeService(backend: FakeCaptureBackend(status: .denied))

        #expect(await service.status == .denied)
    }

    @Test func requestReturnsImmediatelyWhenAlreadyDetermined() async throws {
        let backend = FakeCaptureBackend(status: .authorized)
        let service = makeService(backend: backend)

        let status = try await service.requestAuthorization()

        #expect(status == .authorized)
        #expect(backend.requestCount == 0)
    }

    @Test func requestShowsPromptAndReturnsTheAnswer() async throws {
        let backend = FakeCaptureBackend(answer: .authorized)
        let service = makeService(backend: backend)

        let status = try await service.requestAuthorization()

        #expect(status == .authorized)
        #expect(backend.requestCount == 1)
    }

    @Test func deniedIsAResultNotAnError() async throws {
        let backend = FakeCaptureBackend(answer: .denied)
        let service = makeService(backend: backend)

        let status = try await service.requestAuthorization()

        #expect(status == .denied)
    }

    @Test func concurrentRequestsShareOnePrompt() async throws {
        let backend = FakeCaptureBackend(answer: .authorized, holdRequests: true)
        let service = makeService(backend: backend)

        async let first = service.requestAuthorization()
        async let second = service.requestAuthorization()
        await waitUntil { backend.requestCount >= 1 }
        backend.releaseRequests()

        #expect(try await first == .authorized)
        #expect(try await second == .authorized)
        #expect(backend.requestCount == 1)
    }

    @Test func missingUsageDescriptionThrowsBeforePrompting() async {
        let backend = FakeCaptureBackend()
        let service = makeService(backend: backend) { key in
            throw PermissionError.missingUsageDescription(key: key)
        }

        await #expect(throws: PermissionError.missingUsageDescription(key: "NSCameraUsageDescription")) {
            try await service.requestAuthorization()
        }
        #expect(backend.requestCount == 0)
    }

    @Test func cancellingARequestThrowsCancellationError() async {
        let backend = FakeCaptureBackend(answer: .authorized, holdRequests: true)
        let service = makeService(backend: backend)

        let task = Task { try await service.requestAuthorization() }
        await waitUntil { backend.requestCount >= 1 }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        backend.releaseRequests()
    }

    @Test func aCancelledRequestDoesNotAffectTheOtherWaiters() async throws {
        let backend = FakeCaptureBackend(answer: .authorized, holdRequests: true)
        let service = makeService(backend: backend)

        let cancelled = Task { try await service.requestAuthorization() }
        let survivor = Task { try await service.requestAuthorization() }
        await waitUntil { backend.requestCount >= 1 }
        cancelled.cancel()
        _ = try? await cancelled.value
        backend.releaseRequests()

        #expect(try await survivor.value == .authorized)
    }

    @Test func statusUpdatesEmitTheInitialStatusThenOnlyChanges() async {
        let backend = FakeCaptureBackend(status: .notDetermined)
        let service = makeService(backend: backend)

        var iterator = service.statusUpdates().makeAsyncIterator()
        #expect(await iterator.next() == .notDetermined)

        backend.signalChange()
        backend.setStatus(.denied)
        backend.signalChange()

        #expect(await iterator.next() == .denied)
    }
}
