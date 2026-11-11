//
//  LocationViewState.swift
//  SrdzPermissionsDemo
//
//  Created by Sergio Rodriguez on 11/11/26.
//

import Foundation
import SrdzPermissions

struct PermissionViewData: Equatable {
    let status: String
    let access: String
    let precision: String

    init(_ status: LocationStatus) {
        self.status = String(describing: status.permission)
        self.access = status.access.map { String(describing: $0) } ?? "none"
        self.precision = String(describing: status.precision)
    }
}

struct LocationViewData: Equatable {
    let latitude: String
    let longitude: String
    let accuracy: String

    init(_ location: Location) {
        self.latitude = location.latitude.formatted(.number.precision(.fractionLength(5)))
        self.longitude = location.longitude.formatted(.number.precision(.fractionLength(5)))
        self.accuracy = "\(Int(location.horizontalAccuracy)) m"
    }
}

struct LocationViewState: Equatable {
    var permission = PermissionViewData(.notDetermined)
    var location: LocationViewData?
    var updateCount = 0
    var isFetching = false
    var isTracking = false
    var errorMessage: String?
}
