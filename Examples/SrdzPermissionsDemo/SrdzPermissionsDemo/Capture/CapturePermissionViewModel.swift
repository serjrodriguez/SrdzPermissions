//
//  CapturePermissionViewModel.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import Foundation
import SrdzPermissions

@MainActor @Observable
final class CapturePermissionViewModel {
    private(set) var state: CapturePermissionViewState

    private let permission: any CapturePermissionProviding
    private var requestTask: Task<Void, Never>?

    init(title: String, permission: any CapturePermissionProviding) {
        self.state = CapturePermissionViewState(title: title)
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

    func didTapOpenSettings() {
        Task { await AppSettings.open() }
    }
}
