//
//  NotificationService.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import SrdzPermissionsCore

actor NotificationService: NotificationProviding {
    private let backend: any NotificationBackend

    private var requestInFlight = false
    private var waiters = Waiters<PermissionStatus>()

    init(backend: any NotificationBackend) {
        self.backend = backend
    }

    var status: PermissionStatus {
        get async { await backend.currentStatus() }
    }

    func requestAuthorization(options: NotificationOptions) async throws -> PermissionStatus {
        let current = await backend.currentStatus()
        guard current == .notDetermined else { return current }

        let id = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                if Task.isCancelled {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                waiters.add(id, continuation)
                startRequestIfNeeded(options)
            }
        } onCancel: {
            Task { await self.cancelWaiter(id) }
        }
    }

    nonisolated func statusUpdates() -> AsyncStream<PermissionStatus> {
        let backend = backend
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let task = Task {
                var last = await backend.currentStatus()
                continuation.yield(last)
                for await _ in backend.statusChanges() {
                    let current = await backend.currentStatus()
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

    private func startRequestIfNeeded(_ options: NotificationOptions) {
        guard !requestInFlight else { return }
        requestInFlight = true
        Task { await self.performRequest(options) }
    }

    private func performRequest(_ options: NotificationOptions) async {
        do {
            try await backend.requestAuthorization(options)
            let status = await backend.currentStatus()
            requestInFlight = false
            waiters.resumeAll(returning: status)
        } catch {
            requestInFlight = false
            waiters.resumeAll(throwing: PermissionError.underlying(description: error.localizedDescription))
        }
    }

    private func cancelWaiter(_ id: UUID) {
        waiters.cancel(id)
    }
}
