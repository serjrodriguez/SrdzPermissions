//
//  FakeNotificationProvider.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore
import SrdzPermissionsNotifications

/// A scripted ``NotificationProviding`` for tests. Wrap it in a ``NotificationPermission`` to inject it.
public actor FakeNotificationProvider: NotificationProviding {
    /// The current scripted status.
    public private(set) var status: PermissionStatus
    /// The options of every request so far, in order.
    public private(set) var requestedOptions: [NotificationOptions] = []

    private let authorizationResult: PermissionStatus?
    private let authorizationError: PermissionError?
    private nonisolated let initialStatus: PermissionStatus
    private nonisolated let scriptedStatusChanges: [PermissionStatus]

    /// Creates a fake.
    ///
    /// - Parameters:
    ///   - status: The initial status.
    ///   - authorizationResult: The status adopted when a request is made while undetermined.
    ///   - statusChanges: Statuses emitted by ``statusUpdates()`` after the initial one.
    ///   - authorizationError: An error thrown by ``requestAuthorization(options:)``.
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

    /// Records the options and, if the status is undetermined, adopts the scripted result.
    public func requestAuthorization(options: NotificationOptions) async throws -> PermissionStatus {
        requestedOptions.append(options)
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
