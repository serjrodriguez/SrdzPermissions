//
//  Location.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation

/// A location fix. Negative accuracy, speed and course values mean the system could not determine them.
public struct Location: Sendable, Equatable, Hashable {
    /// Latitude in degrees.
    public var latitude: Double
    /// Longitude in degrees.
    public var longitude: Double

    /// Altitude in meters above sea level.
    public var altitude: Double

    /// Horizontal accuracy in meters; negative when invalid.
    public var horizontalAccuracy: Double
    /// Vertical accuracy in meters; negative when invalid.
    public var verticalAccuracy: Double

    /// Speed in meters per second; negative when invalid.
    public var speed: Double

    /// Direction of travel in degrees from true north; negative when invalid.
    public var course: Double
    /// When the fix was determined.
    public var timestamp: Date

    /// Creates a location.
    ///
    /// - Parameters:
    ///   - latitude: Latitude in degrees.
    ///   - longitude: Longitude in degrees.
    ///   - altitude: Altitude in meters.
    ///   - horizontalAccuracy: Horizontal accuracy in meters; negative when unknown.
    ///   - verticalAccuracy: Vertical accuracy in meters; negative when unknown.
    ///   - speed: Speed in meters per second; negative when unknown.
    ///   - course: Direction of travel in degrees; negative when unknown.
    ///   - timestamp: When the fix was determined.
    public init(
        latitude: Double,
        longitude: Double,
        altitude: Double = 0,
        horizontalAccuracy: Double = -1,
        verticalAccuracy: Double = -1,
        speed: Double = -1,
        course: Double = -1,
        timestamp: Date = Date()
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.speed = speed
        self.course = course
        self.timestamp = timestamp
    }
}
