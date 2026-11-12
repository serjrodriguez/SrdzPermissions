//
//  BluetoothPermission.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

/// Requests and observes Bluetooth access.
///
/// Use `Permissions.bluetooth` for the real implementation. Requires `NSBluetoothAlwaysUsageDescription` in the app's Info.plist. This type only covers the permission; scanning and connecting stay in your own Core Bluetooth code.
///
/// iOS has no request call for Bluetooth: the prompt appears when a central manager is created. The library creates it only when you call ``requestAuthorization()``, so reading ``status`` never prompts.
public struct BluetoothPermission: BluetoothProviding {
    private let provider: any BluetoothProviding

    /// Creates a permission backed by `provider`.
    ///
    /// - Parameter provider: The implementation that answers the calls, usually ``live``.
    public init(provider: any BluetoothProviding) {
        self.provider = provider
    }

    /// The current Bluetooth status. Reading it never shows the system prompt.
    public var status: BluetoothStatus {
        get async { await provider.status }
    }

    /// Asks the user for Bluetooth access if they have not decided yet.
    ///
    /// Concurrent calls share one system prompt.
    ///
    /// - Returns: The status after the request. A denial or a radio that is off is returned, not thrown.
    /// - Throws: ``PermissionError/missingUsageDescription(key:)`` if the Info.plist key is missing, or `CancellationError` if the task is cancelled.
    public func requestAuthorization() async throws -> BluetoothStatus {
        try await provider.requestAuthorization()
    }

    /// Emits the current status and then every change, including radio changes such as the user turning Bluetooth off.
    ///
    /// - Returns: A stream that does not finish on its own; cancel the consuming task to stop it.
    public func statusUpdates() -> AsyncStream<BluetoothStatus> {
        provider.statusUpdates()
    }
}
