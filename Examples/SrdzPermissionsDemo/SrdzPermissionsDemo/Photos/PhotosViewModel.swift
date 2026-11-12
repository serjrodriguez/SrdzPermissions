//
//  PhotosViewModel.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import SrdzPermissions

@MainActor @Observable
final class PhotosViewModel {
    private(set) var state = PhotosViewState()

    private let permission: PhotosPermission
    private var requestTask: Task<Void, Never>?

    init(permission: PhotosPermission) {
        self.permission = permission
    }

    func observeStatus() async {
        for await status in permission.statusUpdates() {
            state.apply(status)
        }
    }

    func onDisappear() {
        requestTask?.cancel()
    }

    func didTapRequestAccess() {
        requestTask?.cancel()
        state.errorMessage = nil
        requestTask = Task {
            do {
                state.apply(try await permission.requestAuthorization())
            } catch is CancellationError {
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }

    func didTapManageSelection() {
        state.errorMessage = nil
        Task {
            do {
                try await permission.presentLimitedLibraryPicker()
            } catch {
                state.errorMessage = error.localizedDescription
            }
        }
    }

    func didTapOpenSettings() {
        Task { await AppSettings.open() }
    }
}
