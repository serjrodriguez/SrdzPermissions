//
//  LocationUpdateOptions.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

/// How precise location updates should be. More precise updates use more battery.
public enum LocationDesiredAccuracy: Sendable, Equatable, Hashable {
    /// The best accuracy the device can provide.
    case best
    /// Accurate to about ten meters.
    case nearestTenMeters
    /// Accurate to about a hundred meters.
    case hundredMeters
    /// Accurate to about a kilometer.
    case kilometer
    /// Accurate to about three kilometers.
    case threeKilometers
}

/// Options for a stream of location updates.
public struct LocationUpdateOptions: Sendable, Equatable, Hashable {
    /// The accuracy to request.
    public var accuracy: LocationDesiredAccuracy

    /// The minimum distance in meters the device must move before a new update; `nil` reports every change.
    public var distanceFilter: Double?
    /// Whether updates continue in the background. It only takes effect if the app declares the `location` background mode.
    public var allowsBackgroundUpdates: Bool

    /// Creates update options.
    ///
    /// - Parameters:
    ///   - accuracy: The accuracy to request.
    ///   - distanceFilter: The minimum distance in meters between updates; `nil` for none.
    ///   - allowsBackgroundUpdates: Whether updates continue in the background.
    public init(
        accuracy: LocationDesiredAccuracy = .best,
        distanceFilter: Double? = nil,
        allowsBackgroundUpdates: Bool = false
    ) {
        self.accuracy = accuracy
        self.distanceFilter = distanceFilter
        self.allowsBackgroundUpdates = allowsBackgroundUpdates
    }
}
