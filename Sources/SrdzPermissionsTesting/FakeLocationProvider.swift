//
//  FakeLocationProvider.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation
import SrdzPermissionsLocation

/// A scripted `LocationProviding` for tests. Wrap it in a `LocationPermission` to inject it.
public actor FakeLocationProvider: LocationProviding {
    /// The current scripted status.
    public private(set) var status: LocationStatus
    /// The access levels requested so far, in order.
    public private(set) var requestedAccess: [LocationAccess] = []

    private let authorizationResult: LocationStatus?
    private let currentLocationResult: Result<Location, PermissionError>
    private nonisolated let scriptedLocations: [Location]
    private nonisolated let scriptedStatusChanges: [LocationStatus]
    private nonisolated let initialStatus: LocationStatus
    private nonisolated let updatesError: PermissionError?

    /// Creates a fake.
    ///
    /// - Parameters:
    ///   - status: The initial status.
    ///   - authorizationResult: The status adopted when a request is made while undetermined.
    ///   - locations: Locations delivered by ``updates(options:)`` before it finishes.
    ///   - statusChanges: Statuses emitted by ``statusUpdates()`` after the initial one.
    ///   - currentLocation: The result of ``currentLocation(timeout:)`` when access is granted.
    ///   - updatesError: The error that ends ``updates(options:)``, or `nil` to finish normally.
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

    /// Records the request and, if the status is undetermined, adopts the scripted result.
    public func requestAuthorization(_ access: LocationAccess) async throws -> LocationStatus {
        requestedAccess.append(access)
        if status.permission == .notDetermined, let authorizationResult {
            status = authorizationResult
        }
        return status
    }

    /// Emits the initial status and then the scripted changes, and finishes.
    public nonisolated func statusUpdates() -> AsyncStream<LocationStatus> {
        let statuses = [initialStatus] + scriptedStatusChanges
        return AsyncStream { continuation in
            for status in statuses { continuation.yield(status) }
            continuation.finish()
        }
    }

    /// Emits the scripted locations and finishes with the scripted error.
    public nonisolated func updates(options: LocationUpdateOptions) -> AsyncThrowingStream<Location, Error> {
        let locations = scriptedLocations
        let error = updatesError
        return AsyncThrowingStream { continuation in
            for location in locations { continuation.yield(location) }
            continuation.finish(throwing: error)
        }
    }

    /// Returns the scripted result, or throws `PermissionError.notAuthorized(_:)` when access is not granted.
    public func currentLocation(timeout: TimeInterval) async throws -> Location {
        guard status.permission.isGranted else {
            throw PermissionError.notAuthorized(status.permission)
        }
        return try currentLocationResult.get()
    }
}
