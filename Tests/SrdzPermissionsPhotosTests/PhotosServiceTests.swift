//
//  PhotosServiceTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import SrdzPermissionsCore
import Testing
@testable import SrdzPermissionsPhotos

private final class FakePhotosBackend: PhotosBackend, @unchecked Sendable {
    private let lock = NSLock()
    private var statuses: [PhotosAccess: PermissionStatus]
    private let answers: [PhotosAccess: PermissionStatus]
    private var requested: [PhotosAccess] = []
    private var pickers = 0

    let changes: AsyncStream<Void>

    init(
        readWrite: PermissionStatus = .notDetermined,
        addOnly: PermissionStatus = .notDetermined,
        answers: [PhotosAccess: PermissionStatus] = [:]
    ) {
        self.statuses = [.readWrite: readWrite, .addOnly: addOnly]
        self.answers = answers
        (changes, _) = AsyncStream.makeStream(of: Void.self)
    }

    var requests: [PhotosAccess] { lock.withLock { requested } }
    var pickerCount: Int { lock.withLock { pickers } }

    func currentStatus(for access: PhotosAccess) -> PermissionStatus {
        lock.withLock { statuses[access] ?? .notDetermined }
    }

    func requestAccess(for access: PhotosAccess) async {
        lock.withLock {
            requested.append(access)
            if let answer = answers[access] { statuses[access] = answer }
        }
    }

    func statusChanges() -> AsyncStream<Void> { changes }

    func presentLimitedPicker() async throws {
        lock.withLock { pickers += 1 }
    }
}

@Suite struct PhotosServiceTests {
    @Test func theUsageDescriptionIsValidatedPerAccessLevel() async throws {
        let backend = FakePhotosBackend(answers: [.readWrite: .authorized, .addOnly: .authorized])
        let service = PhotosService(backend: backend) { access in
            if access == .addOnly { throw PermissionError.missingUsageDescription(key: "NSPhotoLibraryAddUsageDescription") }
        }

        #expect(try await service.requestAuthorization(for: .readWrite) == .authorized)
        await #expect(throws: PermissionError.missingUsageDescription(key: "NSPhotoLibraryAddUsageDescription")) {
            try await service.requestAuthorization(for: .addOnly)
        }
        #expect(backend.requests == [.readWrite])
    }

    @Test func eachAccessLevelHasItsOwnStatus() async throws {
        let backend = FakePhotosBackend(answers: [.addOnly: .authorized])
        let service = PhotosService(backend: backend) { _ in }

        _ = try await service.requestAuthorization(for: .addOnly)

        #expect(await service.status(for: .addOnly) == .authorized)
        #expect(await service.status(for: .readWrite) == .notDetermined)
    }

    @Test func limitedAccessIsAResult() async throws {
        let backend = FakePhotosBackend(answers: [.readWrite: .limited])
        let service = PhotosService(backend: backend) { _ in }

        let status = try await service.requestAuthorization(for: .readWrite)

        #expect(status == .limited)
        #expect(status.isGranted)
    }

    @Test func theLimitedPickerNeedsLimitedAccess() async {
        let backend = FakePhotosBackend(readWrite: .authorized)
        let service = PhotosService(backend: backend) { _ in }

        await #expect(throws: PermissionError.self) {
            try await service.presentLimitedLibraryPicker()
        }
        #expect(backend.pickerCount == 0)
    }

    @Test func theLimitedPickerIsPresentedWhenAccessIsLimited() async throws {
        let backend = FakePhotosBackend(readWrite: .limited)
        let service = PhotosService(backend: backend) { _ in }

        try await service.presentLimitedLibraryPicker()

        #expect(backend.pickerCount == 1)
    }
}
