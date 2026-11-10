//
//  PermissionStatus.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

public enum PermissionStatus: Sendable, Equatable, Hashable {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted

    public var isGranted: Bool {
        self == .authorized || self == .limited
    }
}
