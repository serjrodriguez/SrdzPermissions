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
            LocationView(viewModel: LocationAssembly.makeViewModel())
        }
    }
}
