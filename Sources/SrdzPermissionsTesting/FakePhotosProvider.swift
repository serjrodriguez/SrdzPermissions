//
//  FakePhotosProvider.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore
import SrdzPermissionsPhotos

public actor FakePhotosProvider: PhotosProviding {
    public private(set) var requestedAccess: [PhotosAccess] = []
    public private(set) var limitedPickerPresentations = 0

    private var statuses: [PhotosAccess: PermissionStatus]
    private let authorizationResult: PermissionStatus?
    private let authorizationError: PermissionError?

    public init(
        readWrite: PermissionStatus = .notDetermined,
        addOnly: PermissionStatus = .notDetermined,
        authorizationResult: PermissionStatus? = nil,
        authorizationError: PermissionError? = nil
    ) {
        self.statuses = [.readWrite: readWrite, .addOnly: addOnly]
        self.authorizationResult = authorizationResult
        self.authorizationError = authorizationError
    }

    public func status(for access: PhotosAccess) async -> PermissionStatus {
        statuses[access] ?? .notDetermined
    }

    public func requestAuthorization(for access: PhotosAccess) async throws -> PermissionStatus {
        requestedAccess.append(access)
        if let authorizationError { throw authorizationError }
        if statuses[access] == .notDetermined, let authorizationResult {
            statuses[access] = authorizationResult
        }
        return statuses[access] ?? .notDetermined
    }

    public nonisolated func statusUpdates(for access: PhotosAccess) -> AsyncStream<PermissionStatus> {
        AsyncStream { continuation in
            Task {
                continuation.yield(await self.status(for: access))
                continuation.finish()
            }
        }
    }

    public func presentLimitedLibraryPicker() async throws {
        guard statuses[.readWrite] == .limited else {
            throw PermissionError.unavailable(reason: "Access is not limited.")
        }
        limitedPickerPresentations += 1
    }
}
