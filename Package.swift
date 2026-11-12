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
        .library(name: "SrdzPermissionsTesting", targets: ["SrdzPermissionsTesting"]),
    ],
    targets: [
        .target(name: "SrdzPermissionsCore"),
        .target(name: "SrdzPermissionsLocation", dependencies: ["SrdzPermissionsCore"]),
        .target(name: "SrdzPermissionsCamera", dependencies: ["SrdzPermissionsCore"]),
        .target(name: "SrdzPermissionsBluetooth", dependencies: ["SrdzPermissionsCore"]),
        .target(name: "SrdzPermissionsNotifications", dependencies: ["SrdzPermissionsCore"]),
        .target(name: "SrdzPermissionsTesting", dependencies: ["SrdzPermissionsLocation", "SrdzPermissionsCamera", "SrdzPermissionsBluetooth", "SrdzPermissionsNotifications"]),
        .target(name: "SrdzPermissions", dependencies: ["SrdzPermissionsCore", "SrdzPermissionsLocation", "SrdzPermissionsCamera", "SrdzPermissionsBluetooth", "SrdzPermissionsNotifications"]),
        .testTarget(name: "SrdzPermissionsCoreTests", dependencies: ["SrdzPermissionsCore"]),
        .testTarget(name: "SrdzPermissionsNotificationsTests", dependencies: ["SrdzPermissionsNotifications", "SrdzPermissionsTesting"]),
        .testTarget(name: "SrdzPermissionsBluetoothTests", dependencies: ["SrdzPermissionsBluetooth", "SrdzPermissionsTesting"]),
        .testTarget(name: "SrdzPermissionsCameraTests", dependencies: ["SrdzPermissionsCamera", "SrdzPermissionsTesting"]),
        .testTarget(name: "SrdzPermissionsLocationTests", dependencies: ["SrdzPermissionsLocation", "SrdzPermissionsTesting"]),
    ]
)
