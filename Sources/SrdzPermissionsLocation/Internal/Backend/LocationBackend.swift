//
//  LocationBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

enum LocationBackendEvent: Sendable, Equatable {
    case authorizationChanged(LocationStatus)
    case locationsUpdated([Location])
    case failed(PermissionError)
}

protocol LocationBackend: Sendable {
    var events: AsyncStream<LocationBackendEvent> { get }

    func currentStatus() async -> LocationStatus
    func requestAuthorization(_ access: LocationAccess) async
    func startUpdates(_ options: LocationUpdateOptions) async
    func stopUpdates() async
    func requestOneShot() async
}
