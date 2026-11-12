//
//  PermissionProviding.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 12/11/26.
//

public protocol PermissionProviding: Sendable {
    var status: PermissionStatus { get async }

    func requestAuthorization() async throws -> PermissionStatus

    func statusUpdates() -> AsyncStream<PermissionStatus>
}
