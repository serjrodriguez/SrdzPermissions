//
//  AuthorizationService.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation

package struct Unscoped: Hashable, Sendable {
    package init() {}
}

package actor AuthorizationService<Scope: Hashable & Sendable> {
    package typealias StatusReader = @Sendable (Scope) async -> PermissionStatus
    package typealias Requester = @Sendable (Scope) async throws -> Void
    package typealias ChangeSignals = @Sendable () -> AsyncStream<Void>

    private let readStatus: StatusReader
    private let performRequest: Requester
    private let changeSignals: ChangeSignals

    private var inFlight: [Scope: Waiters<PermissionStatus>] = [:]

    package init(
        readStatus: @escaping StatusReader,
        performRequest: @escaping Requester,
        changeSignals: @escaping ChangeSignals
    ) {
        self.readStatus = readStatus
        self.performRequest = performRequest
        self.changeSignals = changeSignals
    }

    package func status(for scope: Scope) async -> PermissionStatus {
        await readStatus(scope)
    }

    package func requestAuthorization(for scope: Scope) async throws -> PermissionStatus {
        let current = await readStatus(scope)
        guard current == .notDetermined else { return current }

        let id = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                if Task.isCancelled {
                    continuation.resume(throwing: CancellationError())
                } else if inFlight[scope] != nil {
                    inFlight[scope]?.add(id, continuation)
                } else {
                    var waiters = Waiters<PermissionStatus>()
                    waiters.add(id, continuation)
                    inFlight[scope] = waiters
                    Task { await self.run(scope) }
                }
            }
        } onCancel: {
            Task { await self.cancelWaiter(id, scope: scope) }
        }
    }

    package nonisolated func statusUpdates(for scope: Scope) -> AsyncStream<PermissionStatus> {
        let readStatus = readStatus
        let changeSignals = changeSignals
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let task = Task {
                var last = await readStatus(scope)
                continuation.yield(last)
                for await _ in changeSignals() {
                    let current = await readStatus(scope)
                    if current != last {
                        last = current
                        continuation.yield(current)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func run(_ scope: Scope) async {
        do {
            try await performRequest(scope)
            let status = await readStatus(scope)
            var waiters = inFlight.removeValue(forKey: scope)
            waiters?.resumeAll(returning: status)
        } catch {
            let mapped = (error as? PermissionError) ?? .underlying(description: error.localizedDescription)
            var waiters = inFlight.removeValue(forKey: scope)
            waiters?.resumeAll(throwing: mapped)
        }
    }

    private func cancelWaiter(_ id: UUID, scope: Scope) {
        inFlight[scope]?.cancel(id)
    }
}
