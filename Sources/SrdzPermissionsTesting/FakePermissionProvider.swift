//
//  FakePermissionProvider.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SrdzPermissionsCore

/// A scripted `PermissionProviding` for tests. It serves `CameraPermission`, `MicrophonePermission` and `TrackingPermission`.
public actor FakePermissionProvider: PermissionProviding {
    /// The current scripted status.
    public private(set) var status: PermissionStatus
    /// How many times authorization was requested.
    public private(set) var requestCount = 0

    private let authorizationResult: PermissionStatus?
    private nonisolated let initialStatus: PermissionStatus
    private nonisolated let scriptedStatusChanges: [PermissionStatus]
    private let authorizationError: PermissionError?

    /// Creates a fake.
    ///
    /// - Parameters:
    ///   - status: The initial status.
    ///   - authorizationResult: The status adopted when a request is made while undetermined.
    ///   - statusChanges: Statuses emitted by ``statusUpdates()`` after the initial one.
    ///   - authorizationError: An error thrown by ``requestAuthorization()``.
    public init(
        status: PermissionStatus = .notDetermined,
        authorizationResult: PermissionStatus? = nil,
        statusChanges: [PermissionStatus] = [],
        authorizationError: PermissionError? = nil
    ) {
        self.status = status
        self.initialStatus = status
        self.authorizationResult = authorizationResult
        self.scriptedStatusChanges = statusChanges
        self.authorizationError = authorizationError
    }

    /// Counts the request and, if the status is undetermined, adopts the scripted result.
    public func requestAuthorization() async throws -> PermissionStatus {
        requestCount += 1
        if let authorizationError { throw authorizationError }
        if status == .notDetermined, let authorizationResult {
            status = authorizationResult
        }
        return status
    }

    /// Emits the initial status and then the scripted changes, and finishes.
    public nonisolated func statusUpdates() -> AsyncStream<PermissionStatus> {
        let statuses = [initialStatus] + scriptedStatusChanges
        return AsyncStream { continuation in
            for status in statuses { continuation.yield(status) }
            continuation.finish()
        }
    }
}
