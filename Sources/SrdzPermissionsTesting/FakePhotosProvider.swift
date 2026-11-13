//
//  FakePhotosProvider.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore
import SrdzPermissionsPhotos

/// A scripted `PhotosProviding` for tests. Wrap it in a `PhotosPermission` to inject it.
public actor FakePhotosProvider: PhotosProviding {
    /// The access levels requested so far, in order.
    public private(set) var requestedAccess: [PhotosAccess] = []
    /// How many times the limited library picker was presented.
    public private(set) var limitedPickerPresentations = 0

    private var statuses: [PhotosAccess: PermissionStatus]
    private let authorizationResult: PermissionStatus?
    private let authorizationError: PermissionError?

    /// Creates a fake.
    ///
    /// - Parameters:
    ///   - readWrite: The initial read-write status.
    ///   - addOnly: The initial add-only status.
    ///   - authorizationResult: The status adopted by a level when a request is made while it is undetermined.
    ///   - authorizationError: An error thrown by ``requestAuthorization(for:)``.
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

    /// The scripted status for an access level.
    public func status(for access: PhotosAccess) async -> PermissionStatus {
        statuses[access] ?? .notDetermined
    }

    /// Records the access level and, if its status is undetermined, adopts the scripted result.
    public func requestAuthorization(for access: PhotosAccess) async throws -> PermissionStatus {
        requestedAccess.append(access)
        if let authorizationError { throw authorizationError }
        if statuses[access] == .notDetermined, let authorizationResult {
            statuses[access] = authorizationResult
        }
        return statuses[access] ?? .notDetermined
    }

    /// Emits the current status for the access level and finishes.
    public nonisolated func statusUpdates(for access: PhotosAccess) -> AsyncStream<PermissionStatus> {
        AsyncStream { continuation in
            Task {
                continuation.yield(await self.status(for: access))
                continuation.finish()
            }
        }
    }

    /// Counts the presentation, or throws `PermissionError.unavailable(reason:)` when read-write access is not limited.
    public func presentLimitedLibraryPicker() async throws {
        guard statuses[.readWrite] == .limited else {
            throw PermissionError.unavailable(reason: "Access is not limited.")
        }
        limitedPickerPresentations += 1
    }
}
