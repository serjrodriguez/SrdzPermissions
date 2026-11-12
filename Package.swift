// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SrdzPermissions",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "SrdzPermissions", targets: ["SrdzPermissions"]),
        .library(name: "SrdzPermissionsLocation", targets: ["SrdzPermissionsLocation"]),
        .library(name: "SrdzPermissionsCamera", targets: ["SrdzPermissionsCamera"]),
        .library(name: "SrdzPermissionsBluetooth", targets: ["SrdzPermissionsBluetooth"]),
        .library(name: "SrdzPermissionsNotifications", targets: ["SrdzPermissionsNotifications"]),
        .library(name: "SrdzPermissionsTracking", targets: ["SrdzPermissionsTracking"]),
        .library(name: "SrdzPermissionsPhotos", targets: ["SrdzPermissionsPhotos"]),
        .library(name: "SrdzPermissionsBiometrics", targets: ["SrdzPermissionsBiometrics"]),
        .library(name: "SrdzPermissionsTesting", targets: ["SrdzPermissionsTesting"]),
    ],
    targets: [
        .target(name: "SrdzPermissionsCore"),
        .target(name: "SrdzPermissionsLocation", dependencies: ["SrdzPermissionsCore"]),
        .target(name: "SrdzPermissionsCamera", dependencies: ["SrdzPermissionsCore"]),
        .target(name: "SrdzPermissionsBluetooth", dependencies: ["SrdzPermissionsCore"]),
        .target(name: "SrdzPermissionsNotifications", dependencies: ["SrdzPermissionsCore"]),
        .target(name: "SrdzPermissionsTracking", dependencies: ["SrdzPermissionsCore"]),
        .target(name: "SrdzPermissionsPhotos", dependencies: ["SrdzPermissionsCore"]),
        .target(name: "SrdzPermissionsBiometrics", dependencies: ["SrdzPermissionsCore"]),
        .target(name: "SrdzPermissionsTesting", dependencies: ["SrdzPermissionsCore", "SrdzPermissionsLocation", "SrdzPermissionsCamera", "SrdzPermissionsBluetooth", "SrdzPermissionsNotifications", "SrdzPermissionsTracking", "SrdzPermissionsPhotos", "SrdzPermissionsBiometrics"]),
        .target(name: "SrdzPermissions", dependencies: ["SrdzPermissionsCore", "SrdzPermissionsLocation", "SrdzPermissionsCamera", "SrdzPermissionsBluetooth", "SrdzPermissionsNotifications", "SrdzPermissionsTracking", "SrdzPermissionsPhotos", "SrdzPermissionsBiometrics"]),
        .testTarget(name: "SrdzPermissionsCoreTests", dependencies: ["SrdzPermissionsCore"]),
        .testTarget(name: "SrdzPermissionsTrackingTests", dependencies: ["SrdzPermissionsTracking", "SrdzPermissionsTesting"]),
        .testTarget(name: "SrdzPermissionsPhotosTests", dependencies: ["SrdzPermissionsPhotos", "SrdzPermissionsTesting"]),
        .testTarget(name: "SrdzPermissionsBiometricsTests", dependencies: ["SrdzPermissionsBiometrics", "SrdzPermissionsTesting"]),
        .testTarget(name: "SrdzPermissionsNotificationsTests", dependencies: ["SrdzPermissionsNotifications", "SrdzPermissionsTesting"]),
        .testTarget(name: "SrdzPermissionsBluetoothTests", dependencies: ["SrdzPermissionsBluetooth", "SrdzPermissionsTesting"]),
        .testTarget(name: "SrdzPermissionsCameraTests", dependencies: ["SrdzPermissionsCamera", "SrdzPermissionsTesting"]),
        .testTarget(name: "SrdzPermissionsLocationTests", dependencies: ["SrdzPermissionsLocation", "SrdzPermissionsTesting"]),
    ]
)
