//
//  CaptureAssembly.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SrdzPermissions

enum CaptureAssembly {
    @MainActor
    static func makeCameraViewModel() -> PermissionViewModel {
        PermissionViewModel(title: "Camera", permission: Permissions.camera)
    }

    @MainActor
    static func makeMicrophoneViewModel() -> PermissionViewModel {
        PermissionViewModel(title: "Microphone", permission: Permissions.microphone)
    }
}
