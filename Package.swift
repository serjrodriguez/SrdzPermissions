// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SrdzPermissions",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "SrdzPermissions", targets: ["SrdzPermissions"]),
        .library(name: "SrdzPermissionsLocation", targets: ["SrdzPermissionsLocation"]),
    ],
    targets: [
        .target(name: "SrdzPermissionsCore"),
        .target(name: "SrdzPermissionsLocation", dependencies: ["SrdzPermissionsCore"]),
        .target(name: "SrdzPermissions", dependencies: ["SrdzPermissionsCore", "SrdzPermissionsLocation"]),
        .testTarget(name: "SrdzPermissionsCoreTests", dependencies: ["SrdzPermissionsCore"]),
        .testTarget(name: "SrdzPermissionsLocationTests", dependencies: ["SrdzPermissionsLocation"]),
    ]
)
