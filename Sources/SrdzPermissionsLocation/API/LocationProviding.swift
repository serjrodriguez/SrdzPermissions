//
//  LocationProviding.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation

/// A source of location authorization and updates. ``LocationPermission`` is the facade apps use; conform to this protocol to provide a fake.
public protocol LocationProviding: Sendable {
    /// The current location status.
    var status: LocationStatus { get async }

    /// Asks the user for location access if they have not decided yet.
    ///
    /// - Parameter access: The level of access to ask for.
    /// - Returns: The status after the request. A denial is returned, not thrown.
    /// - Throws: A ``PermissionError`` if the request cannot be made, or `CancellationError` if the task is cancelled.
    func requestAuthorization(_ access: LocationAccess) async throws -> LocationStatus

    /// Emits the current status and then every change.
    ///
    /// - Returns: A stream that does not finish on its own; cancel the consuming task to stop it.
    func statusUpdates() -> AsyncStream<LocationStatus>

    /// Streams location updates.
    ///
    /// - Parameter options: The accuracy and filtering to request.
    /// - Returns: A stream that ends with ``PermissionError/notAuthorized(_:)`` if access is missing or revoked.
    func updates(options: LocationUpdateOptions) -> AsyncThrowingStream<Location, Error>

    /// Returns a single location fix.
    ///
    /// - Parameter timeout: Seconds to wait for a fix.
    /// - Throws: ``PermissionError/notAuthorized(_:)`` without access, or ``PermissionError/timeout`` if no fix arrives in time.
    func currentLocation(timeout: TimeInterval) async throws -> Location
}
