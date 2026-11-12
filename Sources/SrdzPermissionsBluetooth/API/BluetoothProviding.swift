//
//  BluetoothProviding.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

/// A source of Bluetooth authorization status. ``BluetoothPermission`` is the facade apps use; conform to this protocol to provide a fake.
public protocol BluetoothProviding: Sendable {
    /// The current Bluetooth status. Reading it never shows the system prompt.
    var status: BluetoothStatus { get async }

    /// Asks the user for Bluetooth access if they have not decided yet.
    ///
    /// - Returns: The status after the request. A denial is returned, not thrown.
    /// - Throws: A ``PermissionError`` if the request cannot be made, or `CancellationError` if the task is cancelled.
    func requestAuthorization() async throws -> BluetoothStatus

    /// Emits the current status and then every change, including radio changes.
    ///
    /// - Returns: A stream that does not finish on its own; cancel the consuming task to stop it.
    func statusUpdates() -> AsyncStream<BluetoothStatus>
}
