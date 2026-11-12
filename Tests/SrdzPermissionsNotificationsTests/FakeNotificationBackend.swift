//
//  FakeNotificationBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import SrdzPermissionsCore
@testable import SrdzPermissionsNotifications

actor FakeNotificationBackend: NotificationBackend {
    private nonisolated let changes: AsyncStream<Void>
    private nonisolated let changesContinuation: AsyncStream<Void>.Continuation

    private(set) var status: PermissionStatus
    private(set) var requestedOptions: [NotificationOptions] = []

    private var answer: PermissionStatus?
    private var failure: (any Error)?
    private var holding: Bool
    private var parked: CheckedContinuation<Void, Never>?

    init(
        status: PermissionStatus = .notDetermined,
        answer: PermissionStatus? = nil,
        failure: (any Error)? = nil,
        holdRequests: Bool = false
    ) {
        self.status = status
        self.answer = answer
        self.failure = failure
        self.holding = holdRequests
        (changes, changesContinuation) = AsyncStream.makeStream(of: Void.self)
    }

    func setStatus(_ newStatus: PermissionStatus) {
        status = newStatus
    }

    func releaseRequests() {
        holding = false
        parked?.resume()
        parked = nil
    }

    nonisolated func signalChange() {
        changesContinuation.yield()
    }

    func currentStatus() async -> PermissionStatus { status }

    func requestAuthorization(_ options: NotificationOptions) async throws {
        requestedOptions.append(options)
        if holding {
            await withCheckedContinuation { parked = $0 }
        }
        if let failure { throw failure }
        if let answer { status = answer }
    }

    nonisolated func statusChanges() -> AsyncStream<Void> { changes }
}

struct FakeFailure: Error, LocalizedError {
    var errorDescription: String? { "boom" }
}

func waitUntil(_ condition: @Sendable () async -> Bool) async {
    for _ in 0..<10_000 {
        if await condition() { return }
        await Task.yield()
    }
}
