//
//  PhotosView.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SwiftUI

struct PhotosView: View {
    @State private var viewModel: PhotosViewModel

    init(viewModel: PhotosViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section("Permission") {
                LabeledContent("Status", value: viewModel.state.status)
                Button("Request access") {
                    viewModel.didTapRequestAccess()
                }
                if viewModel.state.canManageSelection {
                    Button("Manage selected photos") {
                        viewModel.didTapManageSelection()
                    }
                }
                if viewModel.state.canOpenSettings {
                    Button("Open Settings") {
                        viewModel.didTapOpenSettings()
                    }
                }
            }

            if let errorMessage = viewModel.state.errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Photos")
        .task { await viewModel.observeStatus() }
        .onDisappear { viewModel.onDisappear() }
    }
}
