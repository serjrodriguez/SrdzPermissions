//
//  LocationProviding.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation

public protocol LocationProviding: Sendable {
    var status: LocationStatus { get async }

    func requestAuthorization(_ access: LocationAccess) async throws -> LocationStatus

    func statusUpdates() -> AsyncStream<LocationStatus>

    func updates(options: LocationUpdateOptions) -> AsyncThrowingStream<Location, Error>

    func currentLocation(timeout: TimeInterval) async throws -> Location
}
