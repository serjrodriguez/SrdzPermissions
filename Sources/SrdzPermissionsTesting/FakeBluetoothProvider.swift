//
//  FakeBluetoothProvider.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsBluetooth
import SrdzPermissionsCore

public actor FakeBluetoothProvider: BluetoothProviding {
    public private(set) var status: BluetoothStatus
    public private(set) var requestCount = 0

    private let authorizationResult: BluetoothStatus?
    private let authorizationError: PermissionError?
    private nonisolated let initialStatus: BluetoothStatus
    private nonisolated let scriptedStatusChanges: [BluetoothStatus]

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

    public func requestAuthorization() async throws -> BluetoothStatus {
        requestCount += 1
        if let authorizationError { throw authorizationError }
        if status.permission == .notDetermined, let authorizationResult {
            status = authorizationResult
        }
        return status
    }

    public nonisolated func statusUpdates() -> AsyncStream<BluetoothStatus> {
        let statuses = [initialStatus] + scriptedStatusChanges
        return AsyncStream { continuation in
            for status in statuses { continuation.yield(status) }
            continuation.finish()
        }
    }
}
