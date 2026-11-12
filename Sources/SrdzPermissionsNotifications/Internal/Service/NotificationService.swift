//
//  NotificationService.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

struct NotificationService: NotificationProviding {
    private let core: AuthorizationService<NotificationOptions>

    init(backend: any NotificationBackend) {
        self.core = AuthorizationService(
            readStatus: { _ in await backend.currentStatus() },
            performRequest: { options in try await backend.requestAuthorization(options) },
            changeSignals: { backend.statusChanges() }
        )
    }

    var status: PermissionStatus {
        get async { await core.status(for: .standard) }
    }

    func requestAuthorization(options: NotificationOptions) async throws -> PermissionStatus {
        try await core.requestAuthorization(for: options)
    }

    func statusUpdates() -> AsyncStream<PermissionStatus> {
        core.statusUpdates(for: .standard)
    }
}
