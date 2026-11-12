//
//  SrdzPermissions.swift
//  SrdzPermissions
//
//  Created by Sergio Rodriguez on 10/11/26.
//

@_exported import SrdzPermissionsBiometrics
@_exported import SrdzPermissionsBluetooth
@_exported import SrdzPermissionsCamera
@_exported import SrdzPermissionsCore
@_exported import SrdzPermissionsLocation
@_exported import SrdzPermissionsNotifications
@_exported import SrdzPermissionsPhotos
@_exported import SrdzPermissionsTracking

/// The entry point to every permission with its real implementation.
///
/// Each property returns a facade backed by the system frameworks. In tests, build the facade yourself with a fake from `SrdzPermissionsTesting`. Available on iOS only.
public enum Permissions {
    #if os(iOS)
    /// Location access and updates.
    public static var location: LocationPermission { .live }
    /// Camera access.
    public static var camera: CameraPermission { .live }
    /// Microphone access.
    public static var microphone: MicrophonePermission { .live }
    /// Bluetooth access and radio state.
    public static var bluetooth: BluetoothPermission { .live }
    /// Notification access.
    public static var notifications: NotificationPermission { .live }
    /// App Tracking Transparency.
    public static var tracking: TrackingPermission { .live }
    /// Photo library access.
    public static var photos: PhotosPermission { .live }
    /// Face ID, Touch ID and Optic ID.
    public static var biometrics: BiometricsPermission { .live }
    #endif
}
