//
//  BluetoothView.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SwiftUI

struct BluetoothView: View {
    @State private var viewModel: BluetoothViewModel

    init(viewModel: BluetoothViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Permission") {
                    LabeledContent("Status", value: viewModel.state.permission)
                    LabeledContent("Radio", value: viewModel.state.radio)
                    LabeledContent("Ready to use", value: viewModel.state.isReady ? "yes" : "no")
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
            .navigationTitle("Bluetooth")
            .task { await viewModel.observeStatus() }
            .onDisappear { viewModel.onDisappear() }
        }
    }
}
