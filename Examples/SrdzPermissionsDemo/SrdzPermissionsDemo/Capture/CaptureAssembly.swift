//
//  CaptureAssembly.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SrdzPermissions

enum CaptureAssembly {
    @MainActor
    static func makeCameraViewModel() -> CapturePermissionViewModel {
        CapturePermissionViewModel(title: "Camera", permission: Permissions.camera)
    }

    @MainActor
    static func makeMicrophoneViewModel() -> CapturePermissionViewModel {
        CapturePermissionViewModel(title: "Microphone", permission: Permissions.microphone)
    }
}
