//
//  FakeNotificationProvider.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore
import SrdzPermissionsNotifications

public actor FakeNotificationProvider: NotificationProviding {
    public private(set) var status: PermissionStatus
    public private(set) var requestedOptions: [NotificationOptions] = []

    private let authorizationResult: PermissionStatus?
    private let authorizationError: PermissionError?
    private nonisolated let initialStatus: PermissionStatus
    private nonisolated let scriptedStatusChanges: [PermissionStatus]

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

    public func requestAuthorization(options: NotificationOptions) async throws -> PermissionStatus {
        requestedOptions.append(options)
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
