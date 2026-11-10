//
//  FakeLocationProvider.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation
import SrdzPermissionsLocation

public actor FakeLocationProvider: LocationProviding {
    public private(set) var status: LocationStatus
    public private(set) var requestedAccess: [LocationAccess] = []

    private let authorizationResult: LocationStatus?
    private let currentLocationResult: Result<Location, PermissionError>
    private nonisolated let scriptedLocations: [Location]
    private nonisolated let scriptedStatusChanges: [LocationStatus]
    private nonisolated let initialStatus: LocationStatus
    private nonisolated let updatesError: PermissionError?

    public init(
        status: LocationStatus = .notDetermined,
        authorizationResult: LocationStatus? = nil,
        locations: [Location] = [],
        statusChanges: [LocationStatus] = [],
        currentLocation: Result<Location, PermissionError> = .failure(.timeout),
        updatesError: PermissionError? = nil
    ) {
        self.status = status
        self.initialStatus = status
        self.authorizationResult = authorizationResult
        self.scriptedLocations = locations
        self.scriptedStatusChanges = statusChanges
        self.currentLocationResult = currentLocation
        self.updatesError = updatesError
    }

    public func requestAuthorization(_ access: LocationAccess) async throws -> LocationStatus {
        requestedAccess.append(access)
        if status.permission == .notDetermined, let authorizationResult {
            status = authorizationResult
        }
        return status
    }

    public nonisolated func statusUpdates() -> AsyncStream<LocationStatus> {
        let statuses = [initialStatus] + scriptedStatusChanges
        return AsyncStream { continuation in
            for status in statuses { continuation.yield(status) }
            continuation.finish()
        }
    }

    public nonisolated func updates(options: LocationUpdateOptions) -> AsyncThrowingStream<Location, Error> {
        let locations = scriptedLocations
        let error = updatesError
        return AsyncThrowingStream { continuation in
            for location in locations { continuation.yield(location) }
            continuation.finish(throwing: error)
        }
    }

    public func currentLocation(timeout: TimeInterval) async throws -> Location {
        guard status.permission.isGranted else {
            throw PermissionError.notAuthorized(status.permission)
        }
        return try currentLocationResult.get()
    }
}
