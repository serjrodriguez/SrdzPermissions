//
//  NotificationsViewModel.swift
//  SrdzPermissionsXCFrameworkDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import SrdzPermissions

@MainActor @Observable
final class NotificationsViewModel {
    private(set) var state = NotificationsViewState()

    private let permission: NotificationPermission
    private var requestTask: Task<Void, Never>?

    init(permission: NotificationPermission) {
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
