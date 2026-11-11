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
            LocationView(viewModel: LocationAssembly.makeViewModel())
        }
    }
}
