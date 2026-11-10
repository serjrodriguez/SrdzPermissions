//
//  LocationPermission.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation

public struct LocationPermission: Sendable {
    private let provider: any LocationProviding

    public init(provider: any LocationProviding) {
        self.provider = provider
    }

    public var status: LocationStatus {
        get async { await provider.status }
    }

    public func requestAuthorization(_ access: LocationAccess = .whenInUse) async throws -> LocationStatus {
        try await provider.requestAuthorization(access)
    }

    public func statusUpdates() -> AsyncStream<LocationStatus> {
        provider.statusUpdates()
    }

    public func updates(options: LocationUpdateOptions = LocationUpdateOptions()) -> AsyncThrowingStream<Location, Error> {
        provider.updates(options: options)
    }

    public func currentLocation(timeout: TimeInterval = 10) async throws -> Location {
        try await provider.currentLocation(timeout: timeout)
    }
}
