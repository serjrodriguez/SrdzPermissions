//
//  AuthorizationServiceLifetimeTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import Testing
@testable import SrdzPermissionsCore

private final class Tracked: @unchecked Sendable {
    let changes: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation

    init() {
        (changes, continuation) = AsyncStream.makeStream(of: Void.self)
    }

    func makeService() -> AuthorizationService<Unscoped> {
        AuthorizationService(
            readStatus: { _ in .notDetermined },
            performRequest: { _ in },
            changeSignals: { self.changes }
        )
    }
}

@Suite struct AuthorizationServiceLifetimeTests {
    @Test func everythingIsReleasedAfterAStatusStreamIsCancelled() async {
        weak var weakTracked: Tracked?
        do {
            let tracked = Tracked()
            weakTracked = tracked
            let service = tracked.makeService()

            let consumer = Task {
                for await _ in service.statusUpdates(for: Unscoped()) {}
            }
            await Task.yield()
            consumer.cancel()
            await consumer.value
        }

        for _ in 0..<10_000 where weakTracked != nil {
            await Task.yield()
        }
        #expect(weakTracked == nil)
    }

    @Test func abandonedStatusStreamsAreReleased() async {
        weak var weakTracked: Tracked?
        do {
            let tracked = Tracked()
            weakTracked = tracked
            let service = tracked.makeService()
            _ = service.statusUpdates(for: Unscoped())
        }

        for _ in 0..<10_000 where weakTracked != nil {
            await Task.yield()
        }
        #expect(weakTracked == nil)
    }
}
