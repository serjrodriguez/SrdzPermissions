//
//  PhotosService.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore

struct PhotosService: PhotosProviding {
    typealias UsageValidator = @Sendable (PhotosAccess) throws -> Void

    private let core: AuthorizationService<PhotosAccess>
    private let backend: any PhotosBackend
    private let validateUsageDescription: UsageValidator

    init(
        backend: any PhotosBackend,
        validateUsageDescription: @escaping UsageValidator = PhotosService.validateMainBundle
    ) {
        self.backend = backend
        self.core = AuthorizationService(
            readStatus: { access in backend.currentStatus(for: access) },
            performRequest: { access in await backend.requestAccess(for: access) },
            changeSignals: { backend.statusChanges() }
        )
        self.validateUsageDescription = validateUsageDescription
    }

    static let validateMainBundle: UsageValidator = { access in
        switch access {
        case .readWrite: try InfoPlistValidator.require("NSPhotoLibraryUsageDescription")
        case .addOnly: try InfoPlistValidator.require("NSPhotoLibraryAddUsageDescription")
        }
    }

    func status(for access: PhotosAccess) async -> PermissionStatus {
        await core.status(for: access)
    }

    func requestAuthorization(for access: PhotosAccess) async throws -> PermissionStatus {
        try validateUsageDescription(access)
        return try await core.requestAuthorization(for: access)
    }

    func statusUpdates(for access: PhotosAccess) -> AsyncStream<PermissionStatus> {
        core.statusUpdates(for: access)
    }

    func presentLimitedLibraryPicker() async throws {
        let status = await core.status(for: .readWrite)
        guard status == .limited else {
            throw PermissionError.unavailable(reason: "The limited library picker is only available when access is limited.")
        }
        try await backend.presentLimitedPicker()
    }
}
