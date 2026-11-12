//
//  TrackingPermissionServiceTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import SrdzPermissionsCore
import Testing
@testable import SrdzPermissionsTracking

private final class FakeTrackingBackend: TrackingBackend, @unchecked Sendable {
    private let lock = NSLock()
    private var status: PermissionStatus
    private let answer: PermissionStatus?
    private var requests = 0

    let changes: AsyncStream<Void>
    private let changesContinuation: AsyncStream<Void>.Continuation

    init(status: PermissionStatus = .notDetermined, answer: PermissionStatus? = nil) {
        self.status = status
        self.answer = answer
        (changes, changesContinuation) = AsyncStream.makeStream(of: Void.self)
    }

    var requestCount: Int { lock.withLock { requests } }

    func setStatus(_ newStatus: PermissionStatus) { lock.withLock { status = newStatus } }
    func signalChange() { changesContinuation.yield() }

    func currentStatus() -> PermissionStatus { lock.withLock { status } }

    func requestAccess() async {
        lock.withLock {
            requests += 1
            if let answer { status = answer }
        }
    }

    func statusChanges() -> AsyncStream<Void> { changes }
}

@Suite struct TrackingServiceTests {
    @Test func requestShowsPromptAndReturnsTheAnswer() async throws {
        let backend = FakeTrackingBackend(answer: .authorized)
        let service = AuthorizationService<Unscoped>.makeTrackingService(backend: backend, validateUsageDescription: {})

        #expect(try await service.requestAuthorization() == .authorized)
        #expect(backend.requestCount == 1)
    }

    @Test func deniedIsAResultNotAnError() async throws {
        let backend = FakeTrackingBackend(answer: .denied)
        let service = AuthorizationService<Unscoped>.makeTrackingService(backend: backend, validateUsageDescription: {})

        #expect(try await service.requestAuthorization() == .denied)
    }

    @Test func missingUsageDescriptionThrowsBeforePrompting() async {
        let backend = FakeTrackingBackend()
        let service = AuthorizationService<Unscoped>.makeTrackingService(backend: backend) {
            throw PermissionError.missingUsageDescription(key: "NSUserTrackingUsageDescription")
        }

        await #expect(throws: PermissionError.missingUsageDescription(key: "NSUserTrackingUsageDescription")) {
            try await service.requestAuthorization()
        }
        #expect(backend.requestCount == 0)
    }

    @Test func statusReadsTheBackend() async {
        let service = AuthorizationService<Unscoped>.makeTrackingService(backend: FakeTrackingBackend(status: .restricted), validateUsageDescription: {})

        #expect(await service.status == .restricted)
    }

    @Test func statusUpdatesEmitTheInitialStatusThenOnlyChanges() async {
        let backend = FakeTrackingBackend()
        let service = AuthorizationService<Unscoped>.makeTrackingService(backend: backend, validateUsageDescription: {})

        var iterator = service.statusUpdates().makeAsyncIterator()
        #expect(await iterator.next() == .notDetermined)

        backend.setStatus(.authorized)
        backend.signalChange()

        #expect(await iterator.next() == .authorized)
    }
}
