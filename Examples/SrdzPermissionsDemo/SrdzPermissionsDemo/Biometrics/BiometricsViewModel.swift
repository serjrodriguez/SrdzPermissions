//
//  BiometricsViewModel.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import SrdzPermissions

@MainActor @Observable
final class BiometricsViewModel {
    private(set) var state = BiometricsViewState()

    private let permission: BiometricsPermission
    private var authenticationTask: Task<Void, Never>?

    init(permission: BiometricsPermission) {
        self.permission = permission
    }

    func refreshStatus() async {
        state.apply(await permission.status)
    }

    func onDisappear() {
        authenticationTask?.cancel()
    }

    func didTapAuthenticate() {
        authenticationTask?.cancel()
        state.errorMessage = nil
        state.lastResult = nil
        state.isAuthenticating = true
        authenticationTask = Task {
            do {
                let result = try await permission.authenticate(reason: "Confirm it is you to continue the demo.")
                state.lastResult = String(describing: result)
            } catch is CancellationError {
            } catch {
                state.errorMessage = error.localizedDescription
            }
            state.isAuthenticating = false
            await refreshStatus()
        }
    }
}
