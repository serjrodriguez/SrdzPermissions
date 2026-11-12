//
//  TrackingView.swift
//  SrdzPermissionsXCFrameworkDemo
//
//  Created by Sergio Rodriguez on 12/11/26.
//

import SwiftUI

struct TrackingView: View {
    @State private var viewModel: PermissionViewModel

    init(viewModel: PermissionViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            PermissionSection(viewModel: viewModel)
        }
        .navigationTitle("Tracking")
    }
}
