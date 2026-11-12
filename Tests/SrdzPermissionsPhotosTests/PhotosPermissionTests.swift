//
//  PhotosPermissionTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SrdzPermissionsCore
import SrdzPermissionsPhotos
import SrdzPermissionsTesting
import Testing

@Suite struct PhotosPermissionTests {
    @Test func requestDefaultsToReadWriteAccess() async throws {
        let provider = FakePhotosProvider(authorizationResult: .limited)
        let permission = PhotosPermission(provider: provider)

        #expect(try await permission.requestAuthorization() == .limited)
        #expect(await provider.requestedAccess == [.readWrite])
    }

    @Test func requestForwardsTheAccessLevel() async throws {
        let provider = FakePhotosProvider(authorizationResult: .authorized)
        let permission = PhotosPermission(provider: provider)

        _ = try await permission.requestAuthorization(for: .addOnly)

        #expect(await provider.requestedAccess == [.addOnly])
        #expect(await permission.status(for: .readWrite) == .notDetermined)
        #expect(await permission.status(for: .addOnly) == .authorized)
    }

    @Test func theLimitedPickerIsPresentedOnlyWhenLimited() async throws {
        let limited = FakePhotosProvider(readWrite: .limited)
        try await PhotosPermission(provider: limited).presentLimitedLibraryPicker()
        #expect(await limited.limitedPickerPresentations == 1)

        let full = FakePhotosProvider(readWrite: .authorized)
        await #expect(throws: PermissionError.self) {
            try await PhotosPermission(provider: full).presentLimitedLibraryPicker()
        }
    }

    @Test func statusUpdatesEmitTheCurrentStatus() async {
        let permission = PhotosPermission(provider: FakePhotosProvider(readWrite: .denied))

        var seen: [PermissionStatus] = []
        for await status in permission.statusUpdates() {
            seen.append(status)
        }

        #expect(seen == [.denied])
    }
}
