//
//  BluetoothBackend.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

protocol BluetoothBackend: Sendable {
    var changes: AsyncStream<BluetoothStatus> { get }

    func currentStatus() async -> BluetoothStatus
    func startMonitoring() async
}
