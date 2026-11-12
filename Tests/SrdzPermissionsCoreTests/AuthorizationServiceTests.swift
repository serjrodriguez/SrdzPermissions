//
//  AuthorizationServiceTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import Testing
@testable import SrdzPermissionsCore

private final class Harness: @unchecked Sendable {
    private let lock = NSLock()
    private var statuses: [String: PermissionStatus]
    private var answers: [String: PermissionStatus]
    private var recorded: [String] = []
    private var holding: Bool
    private var parked: [CheckedContinuation<Void, Never>] = []
    private let failure: (any Error)?

    let changes: AsyncStream<Void>
    private let changesContinuation: AsyncStream<Void>.Continuation

    init(
        statuses: [String: PermissionStatus] = [:],
        answers: [String: PermissionStatus] = [:],
        failure: (any Error)? = nil,
        holdRequests: Bool = false
    ) {
        self.statuses = statuses
        self.answers = answers
        self.failure = failure
        self.holding = holdRequests
        (changes, changesContinuation) = AsyncStream.makeStream(of: Void.self)
    }

    var requests: [String] { lock.withLock { recorded } }

    func setStatus(_ status: PermissionStatus, for scope: String) {
        lock.withLock { statuses[scope] = status }
    }

    func signalChange() {
        changesContinuation.yield()
    }

    func release() {
        let pending = lock.withLock { () -> [CheckedContinuation<Void, Never>] in
            holding = false
            defer { parked = [] }
            return parked
        }
        for continuation in pending { continuation.resume() }
    }

    func readStatus(_ scope: String) -> PermissionStatus {
        lock.withLock { statuses[scope] ?? .notDetermined }
    }

    func performRequest(_ scope: String) async throws {
        lock.withLock { recorded.append(scope) }
        await withCheckedContinuation { continuation in
            let shouldResume = lock.withLock { () -> Bool in
                guard holding else { return true }
                parked.append(continuation)
                return false
            }
            if shouldResume { continuation.resume() }
        }
        if let failure { throw failure }
        lock.withLock {
            if let answer = answers[scope] { statuses[scope] = answer }
        }
    }

    func makeService() -> AuthorizationService<String> {
        AuthorizationService(
            readStatus: { self.readStatus($0) },
            performRequest: { try await self.performRequest($0) },
            changeSignals: { self.changes }
        )
    }
}

private struct Boom: Error, LocalizedError {
    var errorDescription: String? { "boom" }
}

private func waitUntil(
    _ condition: @Sendable () async -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    for attempt in 0..<5_000 {
        if await condition() { return }
        if attempt < 100 {
            await Task.yield()
        } else {
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
    }
    Issue.record("The condition was not met within five seconds.", sourceLocation: sourceLocation)
}

@Suite struct AuthorizationServiceTests {
    @Test func theValidatorRunsBeforeAnyRequest() async {
        let harness = Harness(answers: ["a": .authorized])
        let service = AuthorizationService<String>(
            readStatus: { harness.readStatus($0) },
            performRequest: { try await harness.performRequest($0) },
            changeSignals: { harness.changes },
            validate: { scope in throw PermissionError.missingUsageDescription(key: scope) }
        )

        await #expect(throws: PermissionError.missingUsageDescription(key: "a")) {
            try await service.requestAuthorization(for: "a")
        }
        #expect(harness.requests.isEmpty)
    }

    @Test func anUnscopedServiceIsAPermissionProvider() async throws {
        let service = AuthorizationService<Unscoped>(
            readStatus: { _ in .authorized },
            performRequest: { _ in },
            changeSignals: { AsyncStream { $0.finish() } }
        )
        let provider: any PermissionProviding = service

        #expect(await provider.status == .authorized)
        #expect(try await provider.requestAuthorization() == .authorized)
        var iterator = provider.statusUpdates().makeAsyncIterator()
        #expect(await iterator.next() == .authorized)
    }

    @Test func returnsTheCurrentStatusWithoutRequestingWhenDetermined() async throws {
        let harness = Harness(statuses: ["a": .denied])
        let service = harness.makeService()

        #expect(try await service.requestAuthorization(for: "a") == .denied)
        #expect(harness.requests.isEmpty)
    }

    @Test func requestsAndReturnsTheStatusReadAfterwards() async throws {
        let harness = Harness(answers: ["a": .authorized])
        let service = harness.makeService()

        #expect(try await service.requestAuthorization(for: "a") == .authorized)
        #expect(harness.requests == ["a"])
    }

    @Test func concurrentRequestsForTheSameScopeShareOneRequest() async throws {
        let harness = Harness(answers: ["a": .authorized], holdRequests: true)
        let service = harness.makeService()

        async let first = service.requestAuthorization(for: "a")
        async let second = service.requestAuthorization(for: "a")
        await waitUntil { harness.requests.count >= 1 }
        harness.release()

        #expect(try await first == .authorized)
        #expect(try await second == .authorized)
        #expect(harness.requests == ["a"])
    }

    @Test func differentScopesAreIndependentRequests() async throws {
        let harness = Harness(answers: ["a": .authorized, "b": .denied], holdRequests: true)
        let service = harness.makeService()

        async let first = service.requestAuthorization(for: "a")
        async let second = service.requestAuthorization(for: "b")
        await waitUntil { harness.requests.count >= 2 }
        harness.release()

        #expect(try await first == .authorized)
        #expect(try await second == .denied)
        #expect(Set(harness.requests) == ["a", "b"])
    }

    @Test func aFailureReachesEveryWaiterAsAnUnderlyingError() async {
        let harness = Harness(failure: Boom(), holdRequests: true)
        let service = harness.makeService()

        let first = Task { try await service.requestAuthorization(for: "a") }
        let second = Task { try await service.requestAuthorization(for: "a") }
        await waitUntil { harness.requests.count >= 1 }
        harness.release()

        await #expect(throws: PermissionError.underlying(description: "boom")) { try await first.value }
        await #expect(throws: PermissionError.underlying(description: "boom")) { try await second.value }
    }

    @Test func aPermissionErrorIsPassedThroughUnchanged() async {
        let harness = Harness(failure: PermissionError.servicesDisabled)
        let service = harness.makeService()

        await #expect(throws: PermissionError.servicesDisabled) {
            try await service.requestAuthorization(for: "a")
        }
    }

    @Test func aFailedRequestCanBeRetried() async throws {
        let harness = Harness(failure: Boom())
        let service = harness.makeService()

        _ = try? await service.requestAuthorization(for: "a")
        _ = try? await service.requestAuthorization(for: "a")

        #expect(harness.requests == ["a", "a"])
    }

    @Test func cancellingARequestThrowsCancellationError() async {
        let harness = Harness(answers: ["a": .authorized], holdRequests: true)
        let service = harness.makeService()

        let task = Task { try await service.requestAuthorization(for: "a") }
        await waitUntil { harness.requests.count >= 1 }
        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
        harness.release()
    }

    @Test func aCancelledRequestDoesNotAffectTheOtherWaiters() async throws {
        let harness = Harness(answers: ["a": .authorized], holdRequests: true)
        let service = harness.makeService()

        let cancelled = Task { try await service.requestAuthorization(for: "a") }
        let survivor = Task { try await service.requestAuthorization(for: "a") }
        await waitUntil { harness.requests.count >= 1 }
        cancelled.cancel()
        _ = try? await cancelled.value
        harness.release()

        #expect(try await survivor.value == .authorized)
    }

    @Test func statusUpdatesEmitTheInitialStatusThenOnlyChanges() async {
        let harness = Harness()
        let service = harness.makeService()

        var iterator = service.statusUpdates(for: "a").makeAsyncIterator()
        #expect(await iterator.next() == .notDetermined)

        harness.signalChange()
        harness.setStatus(.denied, for: "a")
        harness.signalChange()

        #expect(await iterator.next() == .denied)
    }
}
