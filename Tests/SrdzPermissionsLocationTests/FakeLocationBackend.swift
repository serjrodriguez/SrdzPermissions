//
//  FakeLocationBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation
import Testing
@testable import SrdzPermissionsLocation

actor FakeLocationBackend: LocationBackend {
    nonisolated let events: AsyncStream<LocationBackendEvent>
    private nonisolated let continuation: AsyncStream<LocationBackendEvent>.Continuation

    private(set) var status: LocationStatus
    private(set) var authorizationRequests: [LocationAccess] = []
    private(set) var startCount = 0
    private(set) var stopCount = 0
    private(set) var oneShotCount = 0

    var answerToAuthorizationRequest: LocationStatus?
    var answerToOneShot: Location?

    init(status: LocationStatus = .notDetermined) {
        self.status = status
        (events, continuation) = AsyncStream.makeStream(of: LocationBackendEvent.self)
    }

    func setAnswerToAuthorizationRequest(_ status: LocationStatus?) { answerToAuthorizationRequest = status }
    func setAnswerToOneShot(_ location: Location?) { answerToOneShot = location }

    func emit(_ event: LocationBackendEvent) {
        if case .authorizationChanged(let newStatus) = event { status = newStatus }
        continuation.yield(event)
    }

    func currentStatus() async -> LocationStatus { status }

    func requestAuthorization(_ access: LocationAccess) async {
        authorizationRequests.append(access)
        if let answer = answerToAuthorizationRequest { emit(.authorizationChanged(answer)) }
    }

    func startUpdates(_ options: LocationUpdateOptions) async { startCount += 1 }

    func stopUpdates() async { stopCount += 1 }

    func requestOneShot() async {
        oneShotCount += 1
        if let answer = answerToOneShot { emit(.locationsUpdated([answer])) }
    }
}

extension Location {
    static let mexicoCity = Location(latitude: 19.4326, longitude: -99.1332, horizontalAccuracy: 5)
}

extension LocationStatus {
    static let whenInUse = LocationStatus(permission: .authorized, access: .whenInUse)
    static let denied = LocationStatus(permission: .denied)
}

func waitUntil(
    _ condition: @Sendable () async -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    for _ in 0..<10_000 {
        if await condition() { return }
        await Task.yield()
    }
    Issue.record("Condition was not met in time", sourceLocation: sourceLocation)
}
