//
//  FakePermissionProvider.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SrdzPermissionsCore

public actor FakePermissionProvider: PermissionProviding {
    public private(set) var status: PermissionStatus
    public private(set) var requestCount = 0

    private let authorizationResult: PermissionStatus?
    private nonisolated let initialStatus: PermissionStatus
    private nonisolated let scriptedStatusChanges: [PermissionStatus]
    private let authorizationError: PermissionError?

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

    public func requestAuthorization() async throws -> PermissionStatus {
        requestCount += 1
        if let authorizationError { throw authorizationError }
        if status == .notDetermined, let authorizationResult {
            status = authorizationResult
        }
        return status
    }

    public nonisolated func statusUpdates() -> AsyncStream<PermissionStatus> {
        let statuses = [initialStatus] + scriptedStatusChanges
        return AsyncStream { continuation in
            for status in statuses { continuation.yield(status) }
            continuation.finish()
        }
    }
}
