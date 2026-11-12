//
//  NotificationServiceTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import SrdzPermissionsCore
import Testing
@testable import SrdzPermissionsNotifications

@Suite struct NotificationServiceTests {
    @Test func statusReadsTheBackend() async {
        let service = NotificationService(backend: FakeNotificationBackend(status: .denied))

        #expect(await service.status == .denied)
    }

    @Test func requestReturnsImmediatelyWhenAlreadyDetermined() async throws {
        let backend = FakeNotificationBackend(status: .authorized)
        let service = NotificationService(backend: backend)

        #expect(try await service.requestAuthorization(options: .standard) == .authorized)
        #expect(await backend.requestedOptions.isEmpty)
    }

    @Test func requestShowsPromptAndReturnsTheAnswer() async throws {
        let backend = FakeNotificationBackend(answer: .authorized)
        let service = NotificationService(backend: backend)

        #expect(try await service.requestAuthorization(options: .standard) == .authorized)
        #expect(await backend.requestedOptions == [.standard])
    }

    @Test func theRequestedOptionsReachTheBackend() async throws {
        let backend = FakeNotificationBackend(answer: .limited)
        let service = NotificationService(backend: backend)

        let status = try await service.requestAuthorization(options: [.alert, .provisional])

        #expect(status == .limited)
        #expect(await backend.requestedOptions == [[.alert, .provisional]])
    }

    @Test func deniedIsAResultNotAnError() async throws {
        let backend = FakeNotificationBackend(answer: .denied)
        let service = NotificationService(backend: backend)

        #expect(try await service.requestAuthorization(options: .standard) == .denied)
    }

    @Test func concurrentRequestsShareOnePrompt() async throws {
        let backend = FakeNotificationBackend(answer: .authorized, holdRequests: true)
        let service = NotificationService(backend: backend)

        async let first = service.requestAuthorization(options: .standard)
        async let second = service.requestAuthorization(options: .standard)
        await waitUntil { await backend.requestedOptions.count >= 1 }
        await backend.releaseRequests()

        #expect(try await first == .authorized)
        #expect(try await second == .authorized)
        #expect(await backend.requestedOptions.count == 1)
    }

    @Test func aBackendFailureReachesEveryWaiterAsAnUnderlyingError() async {
        let backend = FakeNotificationBackend(failure: FakeFailure(), holdRequests: true)
        let service = NotificationService(backend: backend)

        let first = Task { try await service.requestAuthorization(options: .standard) }
        let second = Task { try await service.requestAuthorization(options: .standard) }
        await waitUntil { await backend.requestedOptions.count >= 1 }
        await backend.releaseRequests()

        await #expect(throws: PermissionError.underlying(description: "boom")) { try await first.value }
        await #expect(throws: PermissionError.underlying(description: "boom")) { try await second.value }
    }

    @Test func cancellingARequestThrowsCancellationError() async {
        let backend = FakeNotificationBackend(answer: .authorized, holdRequests: true)
        let service = NotificationService(backend: backend)

        let task = Task { try await service.requestAuthorization(options: .standard) }
        await waitUntil { await backend.requestedOptions.count >= 1 }
        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
        await backend.releaseRequests()
    }

    @Test func aCancelledRequestDoesNotAffectTheOtherWaiters() async throws {
        let backend = FakeNotificationBackend(answer: .authorized, holdRequests: true)
        let service = NotificationService(backend: backend)

        let cancelled = Task { try await service.requestAuthorization(options: .standard) }
        let survivor = Task { try await service.requestAuthorization(options: .standard) }
        await waitUntil { await backend.requestedOptions.count >= 1 }
        cancelled.cancel()
        _ = try? await cancelled.value
        await backend.releaseRequests()

        #expect(try await survivor.value == .authorized)
    }

    @Test func statusUpdatesEmitTheInitialStatusThenOnlyChanges() async {
        let backend = FakeNotificationBackend(status: .notDetermined)
        let service = NotificationService(backend: backend)

        var iterator = service.statusUpdates().makeAsyncIterator()
        #expect(await iterator.next() == .notDetermined)

        backend.signalChange()
        await backend.setStatus(.denied)
        backend.signalChange()

        #expect(await iterator.next() == .denied)
    }
}
