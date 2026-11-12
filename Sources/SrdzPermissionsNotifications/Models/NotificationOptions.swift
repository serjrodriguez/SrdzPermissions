//
//  NotificationOptions.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

public struct NotificationOptions: OptionSet, Sendable, Hashable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let alert = NotificationOptions(rawValue: 1 << 0)
    public static let sound = NotificationOptions(rawValue: 1 << 1)
    public static let badge = NotificationOptions(rawValue: 1 << 2)
    public static let provisional = NotificationOptions(rawValue: 1 << 3)

    public static let standard: NotificationOptions = [.alert, .sound, .badge]
}
