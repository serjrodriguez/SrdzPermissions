//
//  SrdzPermissionsDemoApp.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SwiftUI

@main
struct SrdzPermissionsDemoApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                LocationView(viewModel: LocationAssembly.makeViewModel())
                    .tabItem { Label("Location", systemImage: "location") }
                CapturePermissionsView(
                    camera: CaptureAssembly.makeCameraViewModel(),
                    microphone: CaptureAssembly.makeMicrophoneViewModel()
                )
                .tabItem { Label("Capture", systemImage: "camera") }
                BluetoothView(viewModel: BluetoothAssembly.makeViewModel())
                    .tabItem { Label("Bluetooth", systemImage: "antenna.radiowaves.left.and.right") }
                NotificationsView(viewModel: NotificationsAssembly.makeViewModel())
                    .tabItem { Label("Notifications", systemImage: "bell") }
            }
        }
    }
}
