//
//  CapturePermissionService.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import Foundation
import SrdzPermissionsCore

actor CapturePermissionService: CapturePermissionProviding {
    typealias UsageValidator = @Sendable (String) throws -> Void

    private let backend: any CaptureBackend
    private let usageDescriptionKey: String
    private let validateUsageDescription: UsageValidator

    private var requestInFlight = false
    private var waiters = Waiters<PermissionStatus>()

    init(
        backend: any CaptureBackend,
        usageDescriptionKey: String,
        validateUsageDescription: @escaping UsageValidator = CapturePermissionService.validateMainBundle
    ) {
        self.backend = backend
        self.usageDescriptionKey = usageDescriptionKey
        self.validateUsageDescription = validateUsageDescription
    }

    static let validateMainBundle: UsageValidator = { key in
        try InfoPlistValidator.require(key)
    }

    var status: PermissionStatus {
        get async { backend.currentStatus() }
    }

    func requestAuthorization() async throws -> PermissionStatus {
        try validateUsageDescription(usageDescriptionKey)

        let current = backend.currentStatus()
        guard current == .notDetermined else { return current }

        let id = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                if Task.isCancelled {
                    continuation.resume(throwing: CancellationError())
                    return
                }
                waiters.add(id, continuation)
                startRequestIfNeeded()
            }
        } onCancel: {
            Task { await self.cancelWaiter(id) }
        }
    }

    nonisolated func statusUpdates() -> AsyncStream<PermissionStatus> {
        let backend = backend
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let task = Task {
                var last = backend.currentStatus()
                continuation.yield(last)
                for await _ in backend.statusChanges() {
                    let current = backend.currentStatus()
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

    private func startRequestIfNeeded() {
        guard !requestInFlight else { return }
        requestInFlight = true
        Task { await self.performRequest() }
    }

    private func performRequest() async {
        _ = await backend.requestAccess()
        requestInFlight = false
        waiters.resumeAll(returning: backend.currentStatus())
    }

    private func cancelWaiter(_ id: UUID) {
        waiters.cancel(id)
    }
}
