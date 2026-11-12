//
//  CoreBluetoothBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
import CoreBluetooth
import Foundation
import SrdzPermissionsCore

@MainActor
final class CoreBluetoothBackend: NSObject, BluetoothBackend, CBCentralManagerDelegate {
    nonisolated let changes: AsyncStream<BluetoothStatus>
    private nonisolated let continuation: AsyncStream<BluetoothStatus>.Continuation
    private var manager: CBCentralManager?

    override init() {
        let (changes, continuation) = AsyncStream.makeStream(of: BluetoothStatus.self)
        self.changes = changes
        self.continuation = continuation
        super.init()
    }

    deinit {
        continuation.finish()
    }

    func currentStatus() async -> BluetoothStatus {
        Self.status(authorization: CBManager.authorization, state: manager?.state ?? .unknown)
    }

    func startMonitoring() async {
        guard manager == nil else { return }
        manager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionShowPowerAlertKey: false]
        )
    }

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        continuation.yield(Self.status(authorization: CBManager.authorization, state: central.state))
    }

    private nonisolated static func status(authorization: CBManagerAuthorization, state: CBManagerState) -> BluetoothStatus {
        BluetoothStatus(permission: PermissionStatus(authorization), radio: BluetoothRadioState(state))
    }
}

private extension PermissionStatus {
    init(_ authorization: CBManagerAuthorization) {
        switch authorization {
        case .notDetermined: self = .notDetermined
        case .restricted: self = .restricted
        case .denied: self = .denied
        case .allowedAlways: self = .authorized
        @unknown default: self = .notDetermined
        }
    }
}

private extension BluetoothRadioState {
    init(_ state: CBManagerState) {
        switch state {
        case .unknown: self = .unknown
        case .resetting: self = .resetting
        case .unsupported: self = .unsupported
        case .unauthorized: self = .unauthorized
        case .poweredOff: self = .poweredOff
        case .poweredOn: self = .poweredOn
        @unknown default: self = .unknown
        }
    }
}
#endif
