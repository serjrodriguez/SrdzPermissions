//
//  ContentView.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SwiftUI
import SrdzPermissions

struct ContentView: View {
    @State private var viewModel = LocationViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section("Permission") {
                    LabeledContent("Status", value: String(describing: viewModel.status.permission))
                    LabeledContent("Access", value: viewModel.status.access.map { String(describing: $0) } ?? "none")
                    LabeledContent("Precision", value: String(describing: viewModel.status.precision))
                    Button("Request access") {
                        Task { await viewModel.requestAccess() }
                    }
                }

                Section("Location") {
                    if let location = viewModel.location {
                        LabeledContent("Latitude", value: location.latitude.formatted(.number.precision(.fractionLength(5))))
                        LabeledContent("Longitude", value: location.longitude.formatted(.number.precision(.fractionLength(5))))
                        LabeledContent("Accuracy", value: "\(Int(location.horizontalAccuracy)) m")
                        LabeledContent("Updates received", value: "\(viewModel.updateCount)")
                    } else {
                        Text("No location yet")
                            .foregroundStyle(.secondary)
                    }
                    Button("Get current location") {
                        Task { await viewModel.fetchCurrentLocation() }
                    }
                    Button(viewModel.isTracking ? "Stop tracking" : "Start tracking") {
                        viewModel.toggleTracking()
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section("Error") {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("SrdzPermissions")
            .task { await viewModel.observeStatus() }
        }
    }
}
