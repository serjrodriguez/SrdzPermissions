//
//  TrackingPermission.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

/// Requests and observes App Tracking Transparency authorization.
///
/// Use `Permissions.tracking` for the real implementation, or inject a ``PermissionProviding`` in tests. Requires `NSUserTrackingUsageDescription` in the app's Info.plist.
///
/// iOS shows the tracking prompt only while the app is active. If you request earlier, the call waits until the app becomes active.
public struct TrackingPermission: PermissionProviding {
    private let provider: any PermissionProviding

    /// Creates a permission backed by `provider`.
    ///
    /// - Parameter provider: The implementation that answers the calls, usually ``live``.
    public init(provider: any PermissionProviding) {
        self.provider = provider
    }

    /// The current authorization status.
    public var status: PermissionStatus {
        get async { await provider.status }
    }

    /// Asks the user for access if they have not decided yet.
    ///
    /// If the status is already determined it is returned without prompting. Concurrent calls share one system prompt, and cancelling a call does not dismiss the prompt.
    ///
    /// - Returns: The status after the request. A denial is returned, not thrown.
    /// - Throws: ``PermissionError/missingUsageDescription(key:)`` if the Info.plist key is missing, or `CancellationError` if the task is cancelled.
    public func requestAuthorization() async throws -> PermissionStatus {
        try await provider.requestAuthorization()
    }

    /// Emits the current status and then every change.
    ///
    /// Changes are detected when the app becomes active, so one made in Settings is reported when the user returns.
    ///
    /// - Returns: A stream that does not finish on its own; cancel the consuming task to stop it.
    public func statusUpdates() -> AsyncStream<PermissionStatus> {
        provider.statusUpdates()
    }
}
