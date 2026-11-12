//
//  BiometricsView.swift
//  SrdzPermissionsXCFrameworkDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SwiftUI

struct BiometricsView: View {
    @State private var viewModel: BiometricsViewModel

    init(viewModel: BiometricsViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section("Biometrics") {
                LabeledContent("Type", value: viewModel.state.type)
                LabeledContent("Availability", value: viewModel.state.availability)
                Button("Authenticate") {
                    viewModel.didTapAuthenticate()
                }
                .disabled(viewModel.state.isAuthenticating)
                if let lastResult = viewModel.state.lastResult {
                    LabeledContent("Result", value: lastResult)
                }
            }

            if let errorMessage = viewModel.state.errorMessage {
                Section("Error") {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Biometrics")
        .task { await viewModel.refreshStatus() }
        .onDisappear { viewModel.onDisappear() }
    }
}
