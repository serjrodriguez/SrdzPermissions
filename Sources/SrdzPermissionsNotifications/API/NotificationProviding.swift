//
//  NotificationProviding.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

/// A source of notification authorization status. ``NotificationPermission`` is the facade apps use; conform to this protocol to provide a fake.
public protocol NotificationProviding: Sendable {
    /// The current authorization status.
    var status: PermissionStatus { get async }

    /// Asks the user for notification access if they have not decided yet.
    ///
    /// - Parameter options: The kinds of notification to ask for.
    /// - Returns: The status after the request. A denial is returned, not thrown.
    /// - Throws: A ``PermissionError`` if the request cannot be made, or `CancellationError` if the task is cancelled.
    func requestAuthorization(options: NotificationOptions) async throws -> PermissionStatus

    /// Emits the current status and then every change.
    ///
    /// - Returns: A stream that does not finish on its own; cancel the consuming task to stop it.
    func statusUpdates() -> AsyncStream<PermissionStatus>
}
