//
//  NotificationOptions.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

/// The kinds of notification the app asks permission for.
public struct NotificationOptions: OptionSet, Sendable, Hashable {
    /// The raw bitmask of the options.
    public let rawValue: Int

    /// Creates options from a raw bitmask.
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Display alerts and banners.
    public static let alert = NotificationOptions(rawValue: 1 << 0)
    /// Play notification sounds.
    public static let sound = NotificationOptions(rawValue: 1 << 1)
    /// Update the badge on the app icon.
    public static let badge = NotificationOptions(rawValue: 1 << 2)
    /// Deliver quietly to Notification Center without showing a prompt. The result is reported as ``PermissionStatus/limited``.
    public static let provisional = NotificationOptions(rawValue: 1 << 3)

    /// ``alert``, ``sound`` and ``badge``, the usual request.
    public static let standard: NotificationOptions = [.alert, .sound, .badge]
}
