//
//  LocationServiceTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

import Foundation
import Testing
@testable import SrdzPermissionsLocation

@Suite struct LocationServiceTests {
    private func makeService(
        backend: FakeLocationBackend,
        validator: @escaping LocationService.UsageValidator = { _ in }
    ) -> LocationService {
        LocationService(makeBackend: { backend }, validateUsageDescriptions: validator)
    }

    @Test func requestReturnsImmediatelyWhenAlreadyDetermined() async throws {
        let backend = FakeLocationBackend(status: .whenInUse)
        let service = makeService(backend: backend)

        let status = try await service.requestAuthorization(.whenInUse)

        #expect(status == .whenInUse)
        #expect(await backend.authorizationRequests.isEmpty)
    }

    @Test func requestShowsPromptAndReturnsTheAnswer() async throws {
        let backend = FakeLocationBackend()
        await backend.setAnswerToAuthorizationRequest(.whenInUse)
        let service = makeService(backend: backend)

        let status = try await service.requestAuthorization(.whenInUse)

        #expect(status == .whenInUse)
        #expect(await backend.authorizationRequests == [.whenInUse])
    }

    @Test func deniedIsAResultNotAnError() async throws {
        let backend = FakeLocationBackend()
        await backend.setAnswerToAuthorizationRequest(.denied)
        let service = makeService(backend: backend)

        let status = try await service.requestAuthorization(.whenInUse)

        #expect(status.permission == .denied)
    }

    @Test func concurrentRequestsShareOnePrompt() async throws {
        let backend = FakeLocationBackend()
        let service = makeService(backend: backend)

        async let first = service.requestAuthorization(.whenInUse)
        async let second = service.requestAuthorization(.whenInUse)
        await waitUntil { await backend.authorizationRequests.count >= 1 }
        await backend.emit(.authorizationChanged(.whenInUse))

        #expect(try await first == .whenInUse)
        #expect(try await second == .whenInUse)
        #expect(await backend.authorizationRequests.count == 1)
    }

    @Test func missingInfoPlistKeyThrowsBeforePrompting() async {
        let backend = FakeLocationBackend()
        let service = makeService(backend: backend) { _ in
            throw PermissionError.missingUsageDescription(key: "NSLocationWhenInUseUsageDescription")
        }

        await #expect(throws: PermissionError.missingUsageDescription(key: "NSLocationWhenInUseUsageDescription")) {
            try await service.requestAuthorization(.whenInUse)
        }
        #expect(await backend.authorizationRequests.isEmpty)
    }

    @Test func cancellingARequestThrowsCancellationError() async {
        let backend = FakeLocationBackend()
        let service = makeService(backend: backend)

        let task = Task { try await service.requestAuthorization(.whenInUse) }
        await waitUntil { await backend.authorizationRequests.count >= 1 }
        task.cancel()

        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func updatesDeliverLocationsAndStopTrackingWhenTheStreamEnds() async throws {
        let backend = FakeLocationBackend(status: .whenInUse)
        let service = makeService(backend: backend)

        let task = Task { () -> Location? in
            for try await location in service.updates(options: LocationUpdateOptions()) {
                return location
            }
            return nil
        }
        await waitUntil { await backend.startCount == 1 }
        await backend.emit(.locationsUpdated([.mexicoCity]))

        #expect(try await task.value == .mexicoCity)
        await waitUntil { await backend.stopCount == 1 }
    }

    @Test func updatesStartTheBackendOnceForSeveralStreams() async throws {
        let backend = FakeLocationBackend(status: .whenInUse)
        let service = makeService(backend: backend)

        let tasks = (0..<2).map { _ in
            Task { for try await _ in service.updates(options: LocationUpdateOptions()) { break } }
        }
        await waitUntil { await service.subscriberCount == 2 }
        await backend.emit(.locationsUpdated([.mexicoCity]))
        for task in tasks { try await task.value }

        await waitUntil { await backend.stopCount == 1 }
        #expect(await backend.startCount == 1)
    }

    @Test func updatesThrowWithoutPermission() async {
        let backend = FakeLocationBackend(status: .denied)
        let service = makeService(backend: backend)

        await #expect(throws: PermissionError.notAuthorized(.denied)) {
            for try await _ in service.updates(options: LocationUpdateOptions()) {}
        }
    }

    @Test func updatesFinishWithAnErrorWhenAccessIsRevoked() async {
        let backend = FakeLocationBackend(status: .whenInUse)
        let service = makeService(backend: backend)

        let task = Task {
            for try await _ in service.updates(options: LocationUpdateOptions()) {}
        }
        await waitUntil { await backend.startCount == 1 }
        await backend.emit(.authorizationChanged(.denied))

        await #expect(throws: PermissionError.notAuthorized(.denied)) { try await task.value }
    }

    @Test func currentLocationReturnsTheFix() async throws {
        let backend = FakeLocationBackend(status: .whenInUse)
        await backend.setAnswerToOneShot(.mexicoCity)
        let service = makeService(backend: backend)

        let location = try await service.currentLocation(timeout: 5)

        #expect(location == .mexicoCity)
    }

    @Test func currentLocationThrowsWithoutPermission() async {
        let service = makeService(backend: FakeLocationBackend(status: .denied))

        await #expect(throws: PermissionError.notAuthorized(.denied)) {
            try await service.currentLocation(timeout: 5)
        }
    }

    @Test func currentLocationTimesOutWhenNoFixArrives() async {
        let service = makeService(backend: FakeLocationBackend(status: .whenInUse))

        await #expect(throws: PermissionError.timeout) {
            try await service.currentLocation(timeout: 0.05)
        }
    }

    @Test func currentLocationPropagatesBackendFailures() async {
        let backend = FakeLocationBackend(status: .whenInUse)
        let service = makeService(backend: backend)

        let task = Task { try await service.currentLocation(timeout: 5) }
        await waitUntil { await backend.oneShotCount == 1 }
        await backend.emit(.failed(.underlying(description: "boom")))

        await #expect(throws: PermissionError.underlying(description: "boom")) { try await task.value }
    }

    @Test func statusUpdatesEmitTheCurrentStatusThenChanges() async {
        let backend = FakeLocationBackend()
        let service = makeService(backend: backend)

        let task = Task { () -> [LocationStatus] in
            var seen: [LocationStatus] = []
            for await status in service.statusUpdates() {
                seen.append(status)
                if seen.count == 2 { break }
            }
            return seen
        }
        await waitUntil { await service.hasStatusSubscribers }
        await backend.emit(.authorizationChanged(.whenInUse))

        #expect(await task.value == [.notDetermined, .whenInUse])
    }
}

extension LocationService {
    var subscriberCount: Int { subscribers.count }
    var hasStatusSubscribers: Bool { !statusSubscribers.isEmpty }
}
