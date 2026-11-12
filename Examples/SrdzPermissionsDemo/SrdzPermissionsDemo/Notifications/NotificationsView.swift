//
//  NotificationsView.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SwiftUI

struct NotificationsView: View {
    @State private var viewModel: NotificationsViewModel

    init(viewModel: NotificationsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section("Permission") {
                LabeledContent("Status", value: viewModel.state.status)
                Button("Request access") {
                    viewModel.didTapRequestAccess()
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
        .navigationTitle("Notifications")
        .task { await viewModel.observeStatus() }
        .onDisappear { viewModel.onDisappear() }
    }
}
