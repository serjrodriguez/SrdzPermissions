# Installing SrdzPermissions manually

Version {{VERSION}}. Requires iOS 15 or later.

Drag the XCFrameworks you need from `Frameworks/` into your app target's **Frameworks, Libraries, and Embedded Content** and set every one to **Do Not Embed**: they are static, so nothing is copied into the app.

Each permission is its own module on purpose. Your app only links the Apple frameworks of the modules you add, so it never references Bluetooth, tracking or photos APIs it does not use.

## What to drag

`SrdzPermissionsCore` is required by every module.

| To use | Drag these |
|---|---|
| Location | `SrdzPermissionsCore`, `SrdzPermissionsLocation` |
| Camera and microphone | `SrdzPermissionsCore`, `SrdzPermissionsCamera` |
| Bluetooth | `SrdzPermissionsCore`, `SrdzPermissionsBluetooth` |
| Notifications | `SrdzPermissionsCore`, `SrdzPermissionsNotifications` |
| Tracking (App Tracking Transparency) | `SrdzPermissionsCore`, `SrdzPermissionsTracking` |
| Photos | `SrdzPermissionsCore`, `SrdzPermissionsPhotos` |
| Face ID and Touch ID | `SrdzPermissionsCore`, `SrdzPermissionsBiometrics` |
| Several permissions | `SrdzPermissionsCore` plus each module you need |
| Every permission and the `Permissions` entry point | `SrdzPermissionsCore`, all seven permission modules and `SrdzPermissions` |

The `Permissions` entry point (`Permissions.location`, `Permissions.camera`, ...) lives in `SrdzPermissions`, which depends on every permission module. If you add only some modules, use each module's `.live` instead, for example `LocationPermission.live`.

## Tests

`Testing/SrdzPermissionsTesting.xcframework` has the fakes for your tests. Add it to test targets only, together with every module it fakes: `SrdzPermissionsCore` and the seven permission modules.

You can skip it by writing your own fake: every facade takes a protocol, and a fake needs only `SrdzPermissionsCore` and the module it fakes. See "Writing your own fake" in the README: https://github.com/serjrodriguez/SrdzPermissions#writing-your-own-fake

## Info.plist

Add the usage description keys for the permissions you use:

| Module | Key |
|---|---|
| Location | `NSLocationWhenInUseUsageDescription`, and `NSLocationAlwaysAndWhenInUseUsageDescription` for `.always` |
| Camera | `NSCameraUsageDescription` |
| Microphone | `NSMicrophoneUsageDescription` |
| Bluetooth | `NSBluetoothAlwaysUsageDescription` |
| Tracking | `NSUserTrackingUsageDescription` |
| Photos | `NSPhotoLibraryUsageDescription`, and `NSPhotoLibraryAddUsageDescription` for add-only access |
| Face ID | `NSFaceIDUsageDescription` |

Notifications and Touch ID need no key. A missing key makes the request throw `PermissionError.missingUsageDescription` instead of failing silently.

## Swift Package Manager instead

If you use Swift Package Manager you do not need any of this: add the package, pick a product such as `SrdzPermissionsLocation`, and its dependencies come with it.
