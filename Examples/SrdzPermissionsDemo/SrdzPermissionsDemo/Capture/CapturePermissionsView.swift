//
//  CapturePermissionsView.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SrdzPermissions
import SwiftUI

struct CapturePermissionsView: View {
    @State private var camera: CapturePermissionViewModel
    @State private var microphone: CapturePermissionViewModel

    init(camera: CapturePermissionViewModel, microphone: CapturePermissionViewModel) {
        _camera = State(wrappedValue: camera)
        _microphone = State(wrappedValue: microphone)
    }

    var body: some View {
        NavigationStack {
            List {
                CapturePermissionSection(viewModel: camera)
                CapturePermissionSection(viewModel: microphone)
            }
            .navigationTitle("Camera & Microphone")
        }
    }
}

private struct CapturePermissionSection: View {
    let viewModel: CapturePermissionViewModel

    var body: some View {
        Section(viewModel.state.title) {
            LabeledContent("Status", value: viewModel.state.status)
            Button("Request access") {
                viewModel.didTapRequestAccess()
            }
            if viewModel.state.canOpenSettings {
                Button("Open Settings") {
                    viewModel.didTapOpenSettings()
                }
            }
            if let errorMessage = viewModel.state.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .task { await viewModel.observeStatus() }
        .onDisappear { viewModel.onDisappear() }
    }
}
