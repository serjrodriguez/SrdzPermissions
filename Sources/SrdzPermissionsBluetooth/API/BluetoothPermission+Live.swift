//
//  BluetoothPermission+Live.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

#if os(iOS)
extension BluetoothPermission {
    public static let live = BluetoothPermission(
        provider: BluetoothService(makeBackend: { await CoreBluetoothBackend() })
    )
}
#endif
