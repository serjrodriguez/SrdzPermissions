//
//  LocationView.swift
//  SrdzPermissionsXCFrameworkDemo
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SwiftUI

struct LocationView: View {
    @State private var viewModel: LocationViewModel

    init(viewModel: LocationViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section("Permission") {
                LabeledContent("Status", value: viewModel.state.permission.status)
                LabeledContent("Access", value: viewModel.state.permission.access)
                LabeledContent("Precision", value: viewModel.state.permission.precision)
                Button("Request access") {
                    viewModel.didTapRequestAccess()
                }
            }

            Section("Location") {
                if let location = viewModel.state.location {
                    LabeledContent("Latitude", value: location.latitude)
                    LabeledContent("Longitude", value: location.longitude)
                    LabeledContent("Accuracy", value: location.accuracy)
                    LabeledContent("Updates received", value: "\(viewModel.state.updateCount)")
                } else {
                    Text("No location yet")
                        .foregroundStyle(.secondary)
                }
                Button("Get current location") {
                    viewModel.didTapGetCurrentLocation()
                }
                .disabled(viewModel.state.isFetching)
                Button(viewModel.state.isTracking ? "Stop tracking" : "Start tracking") {
                    viewModel.didTapToggleTracking()
                }
            }

            if let errorMessage = viewModel.state.errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("SrdzPermissions")
        .task { await viewModel.observeStatus() }
        .onDisappear { viewModel.onDisappear() }
    }
}
