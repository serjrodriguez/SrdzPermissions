//
//  LocationPermission.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation

/// Requests location access and delivers locations.
///
/// Use `Permissions.location` for the real implementation. Requires `NSLocationWhenInUseUsageDescription` in the app's Info.plist, and `NSLocationAlwaysAndWhenInUseUsageDescription` to request ``LocationAccess/always``.
public struct LocationPermission: Sendable {
    private let provider: any LocationProviding

    /// Creates a permission backed by `provider`.
    ///
    /// - Parameter provider: The implementation that answers the calls, usually ``live``.
    public init(provider: any LocationProviding) {
        self.provider = provider
    }

    /// The current location status.
    public var status: LocationStatus {
        get async { await provider.status }
    }

    /// Asks the user for location access if they have not decided yet.
    ///
    /// Concurrent calls share one system prompt.
    ///
    /// - Parameter access: The level of access to ask for. Defaults to ``LocationAccess/whenInUse``.
    /// - Returns: The status after the request. A denial is returned, not thrown.
    /// - Throws: ``PermissionError/missingUsageDescription(key:)`` if an Info.plist key is missing, or `CancellationError` if the task is cancelled.
    public func requestAuthorization(_ access: LocationAccess = .whenInUse) async throws -> LocationStatus {
        try await provider.requestAuthorization(access)
    }

    /// Emits the current status and then every change.
    ///
    /// - Returns: A stream that does not finish on its own; cancel the consuming task to stop it.
    public func statusUpdates() -> AsyncStream<LocationStatus> {
        provider.statusUpdates()
    }

    /// Streams location updates.
    ///
    /// Tracking starts with the first stream and stops when the last one finishes, is cancelled or is released.
    ///
    /// - Parameter options: The accuracy and filtering to request.
    /// - Returns: A stream that ends with ``PermissionError/notAuthorized(_:)`` if access is missing or revoked.
    public func updates(options: LocationUpdateOptions = LocationUpdateOptions()) -> AsyncThrowingStream<Location, Error> {
        provider.updates(options: options)
    }

    /// Returns a single location fix.
    ///
    /// Concurrent calls share one request.
    ///
    /// - Parameter timeout: Seconds to wait for a fix. Very large values are capped, and values that are not positive expire immediately.
    /// - Throws: ``PermissionError/notAuthorized(_:)`` without access, or ``PermissionError/timeout`` if no fix arrives in time.
    public func currentLocation(timeout: TimeInterval = 10) async throws -> Location {
        try await provider.currentLocation(timeout: timeout)
    }
}
