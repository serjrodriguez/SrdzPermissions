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

public enum Permissions {
    #if os(iOS)
    public static var location: LocationPermission { .live }
    public static var camera: CameraPermission { .live }
    public static var microphone: MicrophonePermission { .live }
    public static var bluetooth: BluetoothPermission { .live }
    public static var notifications: NotificationPermission { .live }
    public static var tracking: TrackingPermission { .live }
    public static var photos: PhotosPermission { .live }
    public static var biometrics: BiometricsPermission { .live }
    #endif
}
