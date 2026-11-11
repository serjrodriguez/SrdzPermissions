//
//  LocationViewModel.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import Foundation
import SrdzPermissions

@MainActor @Observable
final class LocationViewModel {
    private(set) var status: LocationStatus = .notDetermined
    private(set) var location: Location?
    private(set) var updateCount = 0
    private(set) var isTracking = false
    private(set) var errorMessage: String?

    private let permission: LocationPermission
    private var trackingTask: Task<Void, Never>?

    init(permission: LocationPermission = Permissions.location) {
        self.permission = permission
    }

    func observeStatus() async {
        for await status in permission.statusUpdates() {
            self.status = status
        }
    }

    func requestAccess() async {
        errorMessage = nil
        do {
            status = try await permission.requestAuthorization()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchCurrentLocation() async {
        errorMessage = nil
        do {
            location = try await permission.currentLocation(timeout: 10)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleTracking() {
        if isTracking {
            trackingTask?.cancel()
            trackingTask = nil
            isTracking = false
            return
        }
        errorMessage = nil
        isTracking = true
        trackingTask = Task { [permission] in
            do {
                for try await update in permission.updates() {
                    location = update
                    updateCount += 1
                }
            } catch is CancellationError {
            } catch {
                errorMessage = error.localizedDescription
            }
            isTracking = false
        }
    }
}
