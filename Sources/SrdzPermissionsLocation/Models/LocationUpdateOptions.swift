//
//  LocationUpdateOptions.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

public enum LocationDesiredAccuracy: Sendable, Equatable, Hashable {
    case best
    case nearestTenMeters
    case hundredMeters
    case kilometer
    case threeKilometers
}

public struct LocationUpdateOptions: Sendable, Equatable, Hashable {
    public var accuracy: LocationDesiredAccuracy

    public var distanceFilter: Double?
    public var allowsBackgroundUpdates: Bool

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
