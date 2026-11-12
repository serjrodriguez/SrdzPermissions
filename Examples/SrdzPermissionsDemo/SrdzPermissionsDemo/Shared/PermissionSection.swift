//
//  PermissionSection.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SwiftUI

struct PermissionSection: View {
    let viewModel: PermissionViewModel

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
