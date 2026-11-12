//
//  CapturePermissionsView.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SrdzPermissions
import SwiftUI

struct CapturePermissionsView: View {
    @State private var camera: PermissionViewModel
    @State private var microphone: PermissionViewModel

    init(camera: PermissionViewModel, microphone: PermissionViewModel) {
        _camera = State(wrappedValue: camera)
        _microphone = State(wrappedValue: microphone)
    }

    var body: some View {
        List {
            PermissionSection(viewModel: camera)
            PermissionSection(viewModel: microphone)
        }
        .navigationTitle("Camera & Microphone")
    }
}
