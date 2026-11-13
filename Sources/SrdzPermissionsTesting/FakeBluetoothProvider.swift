//
//  FakeBluetoothProvider.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsBluetooth
import SrdzPermissionsCore

/// A scripted `BluetoothProviding` for tests. Wrap it in a `BluetoothPermission` to inject it.
public actor FakeBluetoothProvider: BluetoothProviding {
    /// The current scripted status.
    public private(set) var status: BluetoothStatus
    /// How many times authorization was requested.
    public private(set) var requestCount = 0

    private let authorizationResult: BluetoothStatus?
    private let authorizationError: PermissionError?
    private nonisolated let initialStatus: BluetoothStatus
    private nonisolated let scriptedStatusChanges: [BluetoothStatus]

    /// Creates a fake.
    ///
    /// - Parameters:
    ///   - status: The initial status.
    ///   - authorizationResult: The status adopted when a request is made while undetermined.
    ///   - statusChanges: Statuses emitted by ``statusUpdates()`` after the initial one.
    ///   - authorizationError: An error thrown by ``requestAuthorization()``.
    public init(
        status: BluetoothStatus = .notDetermined,
        authorizationResult: BluetoothStatus? = nil,
        statusChanges: [BluetoothStatus] = [],
        authorizationError: PermissionError? = nil
    ) {
        self.status = status
        self.initialStatus = status
        self.authorizationResult = authorizationResult
        self.scriptedStatusChanges = statusChanges
        self.authorizationError = authorizationError
    }

    /// Counts the request and, if the permission is undetermined, adopts the scripted result.
    public func requestAuthorization() async throws -> BluetoothStatus {
        requestCount += 1
        if let authorizationError { throw authorizationError }
        if status.permission == .notDetermined, let authorizationResult {
            status = authorizationResult
        }
        return status
    }

    /// Emits the initial status and then the scripted changes, and finishes.
    public nonisolated func statusUpdates() -> AsyncStream<BluetoothStatus> {
        let statuses = [initialStatus] + scriptedStatusChanges
        return AsyncStream { continuation in
            for status in statuses { continuation.yield(status) }
            continuation.finish()
        }
    }
}
