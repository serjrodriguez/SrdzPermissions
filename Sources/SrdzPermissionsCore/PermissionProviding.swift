//
//  PermissionProviding.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

/// A source of authorization status for a permission that takes no parameters.
///
/// `CameraPermission`, `MicrophonePermission` and `TrackingPermission` conform to it, so one view model, or one fake, can serve any of them.
public protocol PermissionProviding: Sendable {
    /// The current authorization status.
    var status: PermissionStatus { get async }

    /// Asks the user for access if they have not decided yet.
    ///
    /// - Returns: The status after the request. A denial is returned, not thrown.
    /// - Throws: A ``PermissionError`` if the request cannot be made, or `CancellationError` if the task is cancelled.
    func requestAuthorization() async throws -> PermissionStatus

    /// Emits the current status and then every change.
    ///
    /// - Returns: A stream that does not finish on its own; cancel the consuming task to stop it.
    func statusUpdates() -> AsyncStream<PermissionStatus>
}
