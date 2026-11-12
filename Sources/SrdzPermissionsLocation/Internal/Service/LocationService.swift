//
//  LocationService.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation
import SrdzPermissionsCore

actor LocationService: LocationProviding {
    typealias BackendFactory = @Sendable () async -> any LocationBackend
    typealias UsageValidator = @Sendable (LocationAccess) throws -> Void

    private let makeBackend: BackendFactory
    private let validateUsageDescriptions: UsageValidator

    private var startTask: Task<any LocationBackend, Never>?
    private var eventTask: Task<Void, Never>?

    private var lastStatus: LocationStatus = .notDetermined

    private var authorizationRequested = false
    private var authorizationWaiters = Waiters<LocationStatus>()

    private var oneShotInFlight = false
    private var oneShotWaiters = Waiters<Location>()
    private var outcomeSequence = 0
    private var lastOutcome: Result<Location, PermissionError>?

    private(set) var subscribers: [UUID: AsyncThrowingStream<Location, Error>.Continuation] = [:]
    private(set) var statusSubscribers: [UUID: AsyncStream<LocationStatus>.Continuation] = [:]

    init(
        makeBackend: @escaping BackendFactory,
        validateUsageDescriptions: @escaping UsageValidator = LocationService.validateMainBundle
    ) {
        self.makeBackend = makeBackend
        self.validateUsageDescriptions = validateUsageDescriptions
    }

    deinit {
        eventTask?.cancel()
    }

    static let validateMainBundle: UsageValidator = { access in
        try InfoPlistValidator.require("NSLocationWhenInUseUsageDescription")
        if access == .always {
            try InfoPlistValidator.require("NSLocationAlwaysAndWhenInUseUsageDescription")
        }
    }

    var status: LocationStatus {
        get async {
            let backend = await readyBackend()
            return await backend.currentStatus()
        }
    }

    func requestAuthorization(_ access: LocationAccess) async throws -> LocationStatus {
        try validateUsageDescriptions(access)
        let backend = await readyBackend()
        guard lastStatus.permission == .notDetermined else { return lastStatus }

        if !authorizationRequested {
            authorizationRequested = true
            await backend.requestAuthorization(access)
        }
        return try await waitForAuthorizationOutcome()
    }

    nonisolated func statusUpdates() -> AsyncStream<LocationStatus> {
        let (stream, continuation) = AsyncStream.makeStream(of: LocationStatus.self, bufferingPolicy: .bufferingNewest(1))
        let task = Task { await self.serveStatusUpdates(id: UUID(), continuation: continuation) }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }

    nonisolated func updates(options: LocationUpdateOptions) -> AsyncThrowingStream<Location, Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(
            of: Location.self,
            throwing: Error.self,
            bufferingPolicy: .bufferingNewest(1)
        )
        let task = Task { await self.serveUpdates(id: UUID(), continuation: continuation, options: options) }
        continuation.onTermination = { _ in task.cancel() }
        return stream
    }

    func currentLocation(timeout: TimeInterval) async throws -> Location {
        let backend = await readyBackend()
        guard lastStatus.permission.isGranted else {
            throw PermissionError.notAuthorized(lastStatus.permission)
        }

        return try await withThrowingTaskGroup(of: Location.self) { group in
            group.addTask { try await self.awaitOneShotLocation(using: backend) }
            group.addTask {
                try await Task.sleep(nanoseconds: Self.nanoseconds(from: timeout))
                throw PermissionError.timeout
            }
            defer { group.cancelAll() }
            guard let first = try await group.next() else { throw CancellationError() }
            return first
        }
    }

    static func nanoseconds(from timeout: TimeInterval) -> UInt64 {
        guard !timeout.isNaN else { return 0 }
        let seconds = min(max(timeout, 0), maximumTimeout)
        return UInt64(seconds * 1_000_000_000)
    }

    private static let maximumTimeout: TimeInterval = 1_000_000_000

    private func readyBackend() async -> any LocationBackend {
        let task: Task<any LocationBackend, Never>
        if let existing = startTask {
            task = existing
        } else {
            task = Task { await self.bootstrap() }
            startTask = task
        }
        return await task.value
    }

    private func bootstrap() async -> any LocationBackend {
        let backend = await makeBackend()
        lastStatus = await backend.currentStatus()
        eventTask = Task { [weak self] in
            for await event in backend.events {
                await self?.handle(event)
            }
        }
        return backend
    }

    private func handle(_ event: LocationBackendEvent) {
        switch event {
        case .authorizationChanged(let status):
            lastStatus = status
            for continuation in statusSubscribers.values { continuation.yield(status) }
            if status.permission != .notDetermined {
                authorizationRequested = false
                authorizationWaiters.resumeAll(returning: status)
            }
            if !status.permission.isGranted {
                finishSubscribers(throwing: PermissionError.notAuthorized(status.permission))
            }

        case .locationsUpdated(let locations):
            guard let latest = locations.last else { return }
            recordOutcome(.success(latest))
            oneShotWaiters.resumeAll(returning: latest)
            for location in locations {
                for continuation in subscribers.values { continuation.yield(location) }
            }

        case .failed(let error):
            recordOutcome(.failure(error))
            oneShotWaiters.resumeAll(throwing: error)
            finishSubscribers(throwing: error)
        }
    }

    private func recordOutcome(_ outcome: Result<Location, PermissionError>) {
        outcomeSequence += 1
        lastOutcome = outcome
        oneShotInFlight = false
    }

    private func finishSubscribers(throwing error: PermissionError) {
        for continuation in subscribers.values { continuation.finish(throwing: error) }
    }

    private func waitForAuthorizationOutcome() async throws -> LocationStatus {
        let id = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                if Task.isCancelled {
                    continuation.resume(throwing: CancellationError())
                } else if lastStatus.permission != .notDetermined {
                    continuation.resume(returning: lastStatus)
                } else {
                    authorizationWaiters.add(id, continuation)
                }
            }
        } onCancel: {
            Task { await self.cancelAuthorizationWaiter(id) }
        }
    }

    private func cancelAuthorizationWaiter(_ id: UUID) {
        authorizationWaiters.cancel(id)
    }

    private func awaitOneShotLocation(using backend: any LocationBackend) async throws -> Location {
        let sequenceBeforeRequest = outcomeSequence
        if !oneShotInFlight {
            oneShotInFlight = true
            await backend.requestOneShot()
        }

        let id = UUID()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                if Task.isCancelled {
                    continuation.resume(throwing: CancellationError())
                    releaseOneShotRequestIfUnused()
                } else if outcomeSequence > sequenceBeforeRequest, let outcome = lastOutcome {
                    switch outcome {
                    case .success(let location): continuation.resume(returning: location)
                    case .failure(let error): continuation.resume(throwing: error)
                    }
                } else {
                    oneShotWaiters.add(id, continuation)
                }
            }
        } onCancel: {
            Task { await self.cancelOneShotWaiter(id) }
        }
    }

    private func cancelOneShotWaiter(_ id: UUID) {
        oneShotWaiters.cancel(id)
        releaseOneShotRequestIfUnused()
    }

    private func releaseOneShotRequestIfUnused() {
        if oneShotWaiters.isEmpty { oneShotInFlight = false }
    }

    private func serveStatusUpdates(id: UUID, continuation: AsyncStream<LocationStatus>.Continuation) async {
        guard !Task.isCancelled else { return }
        let backend = await readyBackend()
        guard !Task.isCancelled else { return }

        continuation.yield(await backend.currentStatus())
        statusSubscribers[id] = continuation
        await parkUntilCancelled()
        statusSubscribers.removeValue(forKey: id)
    }

    private func serveUpdates(
        id: UUID,
        continuation: AsyncThrowingStream<Location, Error>.Continuation,
        options: LocationUpdateOptions
    ) async {
        guard !Task.isCancelled else { return }
        let backend = await readyBackend()
        guard !Task.isCancelled else { return }

        guard lastStatus.permission.isGranted else {
            continuation.finish(throwing: PermissionError.notAuthorized(lastStatus.permission))
            return
        }

        subscribers[id] = continuation
        if subscribers.count == 1 {
            await backend.startUpdates(options)
        }

        await parkUntilCancelled()

        subscribers.removeValue(forKey: id)
        if subscribers.isEmpty {
            await backend.stopUpdates()
        }
    }

    private func parkUntilCancelled() async {
        try? await Task.sleep(nanoseconds: .max)
    }
}
