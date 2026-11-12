//
//  BluetoothProviding.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

public protocol BluetoothProviding: Sendable {
    var status: BluetoothStatus { get async }

    func requestAuthorization() async throws -> BluetoothStatus

    func statusUpdates() -> AsyncStream<BluetoothStatus>
}
