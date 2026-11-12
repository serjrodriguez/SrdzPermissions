//
//  SrdzPermissionsXCFrameworkDemoApp.swift
//  SrdzPermissionsXCFrameworkDemo
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import SwiftUI

@main
struct SrdzPermissionsXCFrameworkDemoApp: App {
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
            }
        }
    }
}
