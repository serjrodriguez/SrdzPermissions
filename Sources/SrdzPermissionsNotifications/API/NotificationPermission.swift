//
//  NotificationPermission.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

/// Requests and observes permission to send notifications.
///
/// Use `Permissions.notifications` for the real implementation. No Info.plist key is needed. This type only covers the permission; registering for remote notifications and scheduling notifications stay in your app.
public struct NotificationPermission: NotificationProviding {
    private let provider: any NotificationProviding

    /// Creates a permission backed by `provider`.
    ///
    /// - Parameter provider: The implementation that answers the calls, usually ``live``.
    public init(provider: any NotificationProviding) {
        self.provider = provider
    }

    /// The current authorization status. ``PermissionStatus/limited`` means provisional authorization.
    public var status: PermissionStatus {
        get async { await provider.status }
    }

    /// Asks the user for notification access if they have not decided yet.
    ///
    /// Concurrent calls with the same options share one system prompt.
    ///
    /// - Parameter options: The kinds of notification to ask for. Defaults to ``NotificationOptions/standard``.
    /// - Returns: The status after the request. A denial is returned, not thrown.
    /// - Throws: ``PermissionError/underlying(description:)`` if UserNotifications fails, or `CancellationError` if the task is cancelled.
    public func requestAuthorization(options: NotificationOptions = .standard) async throws -> PermissionStatus {
        try await provider.requestAuthorization(options: options)
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
