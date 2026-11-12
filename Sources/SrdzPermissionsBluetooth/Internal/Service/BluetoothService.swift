//
//  BluetoothService.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import SrdzPermissionsCore

actor BluetoothService: BluetoothProviding {
    typealias BackendFactory = @Sendable () async -> any BluetoothBackend
    typealias UsageValidator = @Sendable () throws -> Void

    private struct StatusWaiter {
        let isReady: @Sendable (BluetoothStatus) -> Bool
        let continuation: CheckedContinuation<BluetoothStatus, Error>
    }

    private let makeBackend: BackendFactory
    private let validateUsageDescription: UsageValidator

    private var startTask: Task<any BluetoothBackend, Never>?
    private var eventTask: Task<Void, Never>?

    private var lastStatus: BluetoothStatus = .notDetermined
    private var promptRequested = false
    private var statusWaiters: [UUID: StatusWaiter] = [:]

    private(set) var subscribers: [UUID: AsyncStream<BluetoothStatus>.Continuation] = [:]

    init(
        makeBackend: @escaping BackendFactory,
        validateUsageDescription: @escaping UsageValidator = BluetoothService.validateMainBundle
    ) {
        self.makeBackend = makeBackend
        self.validateUsageDescription = validateUsageDescription
    }

    deinit {
        eventTask?.cancel()
    }

    static let validateMainBundle: UsageValidator = {
        try InfoPlistValidator.require("NSBluetoothAlwaysUsageDescription")
    }

    var status: BluetoothStatus {
        get async {
            let backend = await readyBackend()
            guard lastStatus.permission == .authorized else { return lastStatus }
            await backend.startMonitoring()
            return (try? await waitForStatus { $0.radio != .unknown }) ?? lastStatus
        }
    }

    func requestAuthorization() async throws -> BluetoothStatus {
        try validateUsageDescription()
        let backend = await readyBackend()
        guard lastStatus.permission == .notDetermined else { return await status }

        if !promptRequested {
            promptRequested = true
            await backend.startMonitoring()
        }
        return try await waitForStatus { $0.permission != .notDetermined }
    }

    nonisolated func statusUpdates() -> AsyncStream<BluetoothStatus> {
        let (stream, continuation) = AsyncStream.makeStream(of: BluetoothStatus.self, bufferingPolicy: .bufferingNewest(1))
        let task = Task { await self.serveStatusUpdates(id: UUID(), continuation: continuation) }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }

    private func readyBackend() async -> any BluetoothBackend {
        let task: Task<any BluetoothBackend, Never>
        if let existing = startTask {
            task = existing
        } else {
            task = Task { await self.bootstrap() }
            startTask = task
        }
        return await task.value
    }

    private func bootstrap() async -> any BluetoothBackend {
        let backend = await makeBackend()
        lastStatus = await backend.currentStatus()
        eventTask = Task { [weak self] in
            for await status in backend.changes {
                await self?.handle(status)
            }
        }
        return backend
    }

    private func handle(_ status: BluetoothStatus) {
        let changed = status != lastStatus
        lastStatus = status

        if changed {
            for continuation in subscribers.values { continuation.yield(status) }
        }

        let ready = statusWaiters.filter { $0.value.isReady(status) }
        for (id, waiter) in ready {
            statusWaiters.removeValue(forKey: id)
            waiter.continuation.resume(returning: status)
        }
    }

    private func waitForStatus(_ isReady: @escaping @Sendable (BluetoothStatus) -> Bool) async throws -> BluetoothStatus {
        let id = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                if Task.isCancelled {
                    continuation.resume(throwing: CancellationError())
                } else if isReady(lastStatus) {
                    continuation.resume(returning: lastStatus)
                } else {
                    statusWaiters[id] = StatusWaiter(isReady: isReady, continuation: continuation)
                }
            }
        } onCancel: {
            Task { await self.cancelWaiter(id) }
        }
    }

    private func cancelWaiter(_ id: UUID) {
        statusWaiters.removeValue(forKey: id)?.continuation.resume(throwing: CancellationError())
    }

    private func serveStatusUpdates(id: UUID, continuation: AsyncStream<BluetoothStatus>.Continuation) async {
        guard !Task.isCancelled else { return }
        _ = await status
        guard !Task.isCancelled else { return }

        continuation.yield(lastStatus)
        subscribers[id] = continuation
        await parkUntilCancelled()
        subscribers.removeValue(forKey: id)
    }

    private func parkUntilCancelled() async {
        try? await Task.sleep(nanoseconds: .max)
    }
}
