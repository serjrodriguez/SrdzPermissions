//
//  FakeCaptureBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import Foundation
import Testing
import SrdzPermissionsCore
@testable import SrdzPermissionsCamera

final class FakeCaptureBackend: CaptureBackend, @unchecked Sendable {
    private let lock = NSLock()
    private var status: PermissionStatus
    private var requests = 0
    private var answer: PermissionStatus?
    private var holding = false
    private var parked: CheckedContinuation<Void, Never>?

    private let changes: AsyncStream<Void>
    private let changesContinuation: AsyncStream<Void>.Continuation

    init(status: PermissionStatus = .notDetermined, answer: PermissionStatus? = nil, holdRequests: Bool = false) {
        self.status = status
        self.answer = answer
        self.holding = holdRequests
        (changes, changesContinuation) = AsyncStream.makeStream(of: Void.self)
    }

    var requestCount: Int { lock.withLock { requests } }

    func setStatus(_ newStatus: PermissionStatus) {
        lock.withLock { status = newStatus }
    }

    func signalChange() {
        changesContinuation.yield()
    }

    func releaseRequests() {
        let pending = lock.withLock { () -> CheckedContinuation<Void, Never>? in
            holding = false
            defer { parked = nil }
            return parked
        }
        pending?.resume()
    }

    func currentStatus() -> PermissionStatus {
        lock.withLock { status }
    }

    func requestAccess() async -> Bool {
        lock.withLock { requests += 1 }
        await withCheckedContinuation { continuation in
            let shouldResume = lock.withLock { () -> Bool in
                guard holding else { return true }
                parked = continuation
                return false
            }
            if shouldResume { continuation.resume() }
        }
        return lock.withLock {
            if let answer { status = answer }
            return status.isGranted
        }
    }

    func statusChanges() -> AsyncStream<Void> {
        changes
    }
}


func waitUntil(
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
