//
//  PermissionsHomeView.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SwiftUI

struct PermissionsHomeView: View {
    var body: some View {
        NavigationStack {
            List(DemoFeature.allCases) { feature in
                NavigationLink(value: feature) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.title)
                            Text(feature.summary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: feature.systemImage)
                    }
                }
            }
            .navigationTitle("SrdzPermissions")
            .navigationDestination(for: DemoFeature.self) { feature in
                destination(for: feature)
            }
        }
    }

    @ViewBuilder
    private func destination(for feature: DemoFeature) -> some View {
        switch feature {
        case .location:
            LocationView(viewModel: LocationAssembly.makeViewModel())
        case .capture:
            CapturePermissionsView(
                camera: CaptureAssembly.makeCameraViewModel(),
                microphone: CaptureAssembly.makeMicrophoneViewModel()
            )
        case .bluetooth:
            BluetoothView(viewModel: BluetoothAssembly.makeViewModel())
        case .notifications:
            NotificationsView(viewModel: NotificationsAssembly.makeViewModel())
        case .tracking:
            TrackingView(viewModel: TrackingAssembly.makeViewModel())
        case .photos:
            PhotosView(viewModel: PhotosAssembly.makeViewModel())
        case .biometrics:
            BiometricsView(viewModel: BiometricsAssembly.makeViewModel())
        }
    }
}
