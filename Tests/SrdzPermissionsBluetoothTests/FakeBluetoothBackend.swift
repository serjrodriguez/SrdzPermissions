//
//  FakeBluetoothBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import Foundation
import SrdzPermissionsCore
@testable import SrdzPermissionsBluetooth

actor FakeBluetoothBackend: BluetoothBackend {
    nonisolated let changes: AsyncStream<BluetoothStatus>
    private nonisolated let continuation: AsyncStream<BluetoothStatus>.Continuation

    private(set) var status: BluetoothStatus
    private(set) var startCount = 0
    private let answerOnStart: BluetoothStatus?

    init(status: BluetoothStatus = .notDetermined, answerOnStart: BluetoothStatus? = nil) {
        self.status = status
        self.answerOnStart = answerOnStart
        (changes, continuation) = AsyncStream.makeStream(of: BluetoothStatus.self)
    }

    func emit(_ newStatus: BluetoothStatus) {
        status = newStatus
        continuation.yield(newStatus)
    }

    func currentStatus() async -> BluetoothStatus { status }

    func startMonitoring() async {
        startCount += 1
        if let answerOnStart { emit(answerOnStart) }
    }
}

extension BluetoothStatus {
    static let ready = BluetoothStatus(permission: .authorized, radio: .poweredOn)
    static let poweredOff = BluetoothStatus(permission: .authorized, radio: .poweredOff)
    static let authorizedUnknownRadio = BluetoothStatus(permission: .authorized, radio: .unknown)
    static let denied = BluetoothStatus(permission: .denied, radio: .unauthorized)
}

func waitUntil(_ condition: @Sendable () async -> Bool) async {
    for _ in 0..<10_000 {
        if await condition() { return }
        await Task.yield()
    }
}
