//
//  Location.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation

public struct Location: Sendable, Equatable, Hashable {
    public var latitude: Double
    public var longitude: Double

    public var altitude: Double

    public var horizontalAccuracy: Double
    public var verticalAccuracy: Double

    public var speed: Double

    public var course: Double
    public var timestamp: Date

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
