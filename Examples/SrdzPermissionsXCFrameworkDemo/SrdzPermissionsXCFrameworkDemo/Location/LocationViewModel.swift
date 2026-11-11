//
//  LocationViewModel.swift
//  SrdzPermissionsXCFrameworkDemo
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import Foundation
import SrdzPermissions

@MainActor @Observable
final class LocationViewModel {
    private(set) var state = LocationViewState()

    private let permission: LocationPermission
    private var requestTask: Task<Void, Never>?
    private var fetchTask: Task<Void, Never>?
    private var trackingTask: Task<Void, Never>?

    init(permission: LocationPermission) {
        self.permission = permission
    }

    func observeStatus() async {
        for await status in permission.statusUpdates() {
            state.permission = PermissionViewData(status)
        }
    }

    func onDisappear() {
        requestTask?.cancel()
        fetchTask?.cancel()
        trackingTask?.cancel()
        trackingTask = nil
        state.isTracking = false
    }

    func didTapRequestAccess() {
        requestTask?.cancel()
        state.errorMessage = nil
        requestTask = Task {
            do {
                let status = try await permission.requestAuthorization()
                state.permission = PermissionViewData(status)
            } catch is CancellationError {
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }

    func didTapGetCurrentLocation() {
        fetchTask?.cancel()
        state.errorMessage = nil
        state.isFetching = true
        fetchTask = Task {
            do {
                let location = try await permission.currentLocation(timeout: 10)
                state.location = LocationViewData(location)
            } catch is CancellationError {
            } catch {
                state.errorMessage = error.localizedDescription
            }
            state.isFetching = false
        }
    }

    func didTapToggleTracking() {
        if state.isTracking {
            trackingTask?.cancel()
            trackingTask = nil
            state.isTracking = false
            return
        }
        state.errorMessage = nil
        state.isTracking = true
        trackingTask = Task {
            do {
                for try await update in permission.updates() {
                    state.location = LocationViewData(update)
                    state.updateCount += 1
                }
            } catch is CancellationError {
            } catch {
                state.errorMessage = error.localizedDescription
            }
            state.isTracking = false
        }
    }
}
