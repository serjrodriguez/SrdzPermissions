//
//  BluetoothServiceTests.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import SrdzPermissionsCore
import Testing
@testable import SrdzPermissionsBluetooth

@Suite struct BluetoothServiceTests {
    private func makeService(
        backend: FakeBluetoothBackend,
        validator: @escaping BluetoothService.UsageValidator = {}
    ) -> BluetoothService {
        BluetoothService(makeBackend: { backend }, validateUsageDescription: validator)
    }

    @Test func statusDoesNotStartTheManagerBeforeThePromptIsAnswered() async {
        let backend = FakeBluetoothBackend()
        let service = makeService(backend: backend)

        #expect(await service.status == .notDetermined)
        #expect(await backend.startCount == 0)
    }

    @Test func statusReportsDeniedWithoutStartingTheManager() async {
        let backend = FakeBluetoothBackend(status: .denied)
        let service = makeService(backend: backend)

        #expect(await service.status == .denied)
        #expect(await backend.startCount == 0)
    }

    @Test func statusWaitsForTheFirstRadioReportWhenAuthorized() async {
        let backend = FakeBluetoothBackend(status: .authorizedUnknownRadio, answerOnStart: .ready)
        let service = makeService(backend: backend)

        #expect(await service.status == .ready)
    }

    @Test func requestReturnsImmediatelyWhenAlreadyDetermined() async throws {
        let backend = FakeBluetoothBackend(status: .ready)
        let service = makeService(backend: backend)

        #expect(try await service.requestAuthorization() == .ready)
    }

    @Test func requestStartsTheManagerAndReturnsTheAnswer() async throws {
        let backend = FakeBluetoothBackend(answerOnStart: .ready)
        let service = makeService(backend: backend)

        let status = try await service.requestAuthorization()

        #expect(status == .ready)
        #expect(await backend.startCount == 1)
    }

    @Test func deniedIsAResultNotAnError() async throws {
        let backend = FakeBluetoothBackend(answerOnStart: .denied)
        let service = makeService(backend: backend)

        let status = try await service.requestAuthorization()

        #expect(status.permission == .denied)
    }

    @Test func aPoweredOffRadioIsReportedNotThrown() async throws {
        let backend = FakeBluetoothBackend(answerOnStart: .poweredOff)
        let service = makeService(backend: backend)

        let status = try await service.requestAuthorization()

        #expect(status.permission == .authorized)
        #expect(status.radio == .poweredOff)
        #expect(!status.isReady)
    }

    @Test func concurrentRequestsShareOnePrompt() async throws {
        let backend = FakeBluetoothBackend()
        let service = makeService(backend: backend)

        async let first = service.requestAuthorization()
        async let second = service.requestAuthorization()
        await waitUntil { await backend.startCount >= 1 }
        await backend.emit(.ready)

        #expect(try await first == .ready)
        #expect(try await second == .ready)
        #expect(await backend.startCount == 1)
    }

    @Test func missingUsageDescriptionThrowsBeforePrompting() async {
        let backend = FakeBluetoothBackend()
        let service = makeService(backend: backend) {
            throw PermissionError.missingUsageDescription(key: "NSBluetoothAlwaysUsageDescription")
        }

        await #expect(throws: PermissionError.missingUsageDescription(key: "NSBluetoothAlwaysUsageDescription")) {
            try await service.requestAuthorization()
        }
        #expect(await backend.startCount == 0)
    }

    @Test func cancellingARequestThrowsCancellationError() async {
        let backend = FakeBluetoothBackend()
        let service = makeService(backend: backend)

        let task = Task { try await service.requestAuthorization() }
        await waitUntil { await backend.startCount >= 1 }
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @Test func aCancelledRequestDoesNotAffectTheOtherWaiters() async throws {
        let backend = FakeBluetoothBackend()
        let service = makeService(backend: backend)

        let cancelled = Task { try await service.requestAuthorization() }
        let survivor = Task { try await service.requestAuthorization() }
        await waitUntil { await backend.startCount >= 1 }
        cancelled.cancel()
        _ = try? await cancelled.value
        await backend.emit(.ready)

        #expect(try await survivor.value == .ready)
    }

    @Test func statusUpdatesEmitTheInitialStatusAndRadioChanges() async {
        let backend = FakeBluetoothBackend(status: .ready)
        let service = makeService(backend: backend)

        var iterator = service.statusUpdates().makeAsyncIterator()
        #expect(await iterator.next() == .ready)

        await backend.emit(.poweredOff)

        #expect(await iterator.next() == .poweredOff)
    }

    @Test func statusUpdatesDoNotRepeatAnUnchangedStatus() async {
        let backend = FakeBluetoothBackend(status: .ready)
        let service = makeService(backend: backend)

        var iterator = service.statusUpdates().makeAsyncIterator()
        #expect(await iterator.next() == .ready)

        await backend.emit(.ready)
        await backend.emit(.poweredOff)

        #expect(await iterator.next() == .poweredOff)
    }
}
