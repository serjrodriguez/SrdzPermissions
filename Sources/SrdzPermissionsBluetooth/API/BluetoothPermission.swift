//
//  BluetoothPermission.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

public struct BluetoothPermission: BluetoothProviding {
    private let provider: any BluetoothProviding

    public init(provider: any BluetoothProviding) {
        self.provider = provider
    }

    public var status: BluetoothStatus {
        get async { await provider.status }
    }

    public func requestAuthorization() async throws -> BluetoothStatus {
        try await provider.requestAuthorization()
    }

    public func statusUpdates() -> AsyncStream<BluetoothStatus> {
        provider.statusUpdates()
    }
}
