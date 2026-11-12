# SrdzPermissions

A Swift package for requesting iOS permissions with Swift Concurrency: `async/await`, `AsyncStream` and actors. One consistent API on top of frameworks that mix delegates, completion handlers and async methods.

Location, camera, microphone, Bluetooth, notifications, App Tracking Transparency, photos and biometrics (Face ID and Touch ID) are available today. Contacts, calendar and more are planned.

## Features

- `async/await` permission requests. A denial is returned as a result, not thrown.
- `AsyncThrowingStream` of location updates and `AsyncStream` of permission changes.
- Concurrent requests share one system prompt.
- Cancellation-aware and `Sendable` throughout, built in Swift 6 language mode with strict concurrency.
- One library product per permission, so your app only links the Apple frameworks it uses.
- Testable by design: depend on a facade and swap in a fake.

## Requirements

- iOS 15+
- Xcode 16+ (Swift 6 toolchain)

## Installation

### Swift Package Manager

In Xcode, choose **File > Add Package Dependencies** and enter the repository URL, or add it to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/serjrodriguez/SrdzPermissions.git", branch: "main")
]
```

Then add the products you need to your target:

```swift
.product(name: "SrdzPermissionsLocation", package: "SrdzPermissions")
```

| Product | Contains |
|---|---|
| `SrdzPermissions` | Every permission, plus the `Permissions` entry point |
| `SrdzPermissionsLocation` | Location only |
| `SrdzPermissionsCamera` | Camera and microphone only |
| `SrdzPermissionsBluetooth` | Bluetooth only |
| `SrdzPermissionsNotifications` | Notifications only |
| `SrdzPermissionsTracking` | App Tracking Transparency only |
| `SrdzPermissionsPhotos` | Photos only |
| `SrdzPermissionsBiometrics` | Face ID and Touch ID only |
| `SrdzPermissionsTesting` | Fakes for your tests. Add it to test targets only |

A tagged release will replace `branch: "main"` with a version requirement.

### Local package

Clone the repository, then drag its folder into your Xcode project, or choose **File > Add Package Dependencies > Add Local**. Xcode treats it like any other package, modules included.

### XCFramework

Build the XCFrameworks from the repository root (requires Xcode):

```bash
./Scripts/build-xcframework.sh
```

It writes one static XCFramework per module to `build/xcframeworks/`, plus a `.zip` and a `.zip.checksum` for each. Every one supports iOS 15.0 and later and carries these architectures:

| Slice | Architectures |
|---|---|
| iOS devices | `arm64`, `arm64e` |
| iOS Simulator | `arm64`, `x86_64` |

Add the frameworks to your app's **Frameworks, Libraries, and Embedded Content** and set them to **Do Not Embed**, since they are static. Modules depend on each other, so add the whole chain:

| To use | Add |
|---|---|
| Location only | `SrdzPermissionsCore` and `SrdzPermissionsLocation` |
| Camera and microphone only | `SrdzPermissionsCore` and `SrdzPermissionsCamera` |
| Bluetooth only | `SrdzPermissionsCore` and `SrdzPermissionsBluetooth` |
| Notifications only | `SrdzPermissionsCore` and `SrdzPermissionsNotifications` |
| Tracking, Photos or Biometrics only | `SrdzPermissionsCore` and that module |
| Everything, with the `Permissions` entry point | `SrdzPermissionsCore`, `SrdzPermissionsLocation`, `SrdzPermissionsCamera`, `SrdzPermissionsBluetooth`, `SrdzPermissionsNotifications`, `SrdzPermissionsTracking`, `SrdzPermissionsPhotos`, `SrdzPermissionsBiometrics` and `SrdzPermissions` |
| Fakes for tests | `SrdzPermissionsTesting`, in test targets only, with every module it fakes (`SrdzPermissionsLocation`, `SrdzPermissionsCamera`, `SrdzPermissionsBluetooth`, `SrdzPermissionsNotifications`, `SrdzPermissionsTracking`, `SrdzPermissionsPhotos` and `SrdzPermissionsBiometrics`) |

To use them without the source through Swift Package Manager, attach the zips to a GitHub release and declare binary targets with the release URL and the checksum from the `.checksum` files:

```swift
.binaryTarget(
    name: "SrdzPermissionsCore",
    url: "https://github.com/serjrodriguez/SrdzPermissions/releases/download/<version>/SrdzPermissionsCore.xcframework.zip",
    checksum: "<contents of SrdzPermissionsCore.xcframework.zip.checksum>"
)
```

No release has been published yet.

## Usage

Add the usage description keys your app needs to its Info.plist:

| Key | Needed for |
|---|---|
| `NSLocationWhenInUseUsageDescription` | Any location access |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Requesting `.always` |
| `NSCameraUsageDescription` | Camera access |
| `NSMicrophoneUsageDescription` | Microphone access |
| `NSBluetoothAlwaysUsageDescription` | Bluetooth access |
| `NSUserTrackingUsageDescription` | App Tracking Transparency |
| `NSPhotoLibraryUsageDescription` | Photos, read and write access |
| `NSPhotoLibraryAddUsageDescription` | Photos, add-only access |
| `NSFaceIDUsageDescription` | Face ID |

Notifications need no usage description key.

If a key is missing, `requestAuthorization` throws `PermissionError.missingUsageDescription` instead of failing silently.

### Request permission

```swift
import SrdzPermissions

let status = try await Permissions.location.requestAuthorization()

guard status.permission.isGranted else {
    return
}
```

### Stream location updates

```swift
for try await location in Permissions.location.updates() {
    print(location.latitude, location.longitude)
}
```

The stream ends with `PermissionError.notAuthorized` if access is missing or revoked. Tracking stops when the last stream finishes, is cancelled or is released.

### Get the current location

```swift
let location = try await Permissions.location.currentLocation(timeout: 10)
```

### Observe permission changes

```swift
for await status in Permissions.location.statusUpdates() {
    print(status.permission, status.precision)
}
```

### Camera and microphone

```swift
let camera = try await Permissions.camera.requestAuthorization()
let microphone = try await Permissions.microphone.requestAuthorization()

if camera == .denied {
    await AppSettings.open()
}
```

Both return a `PermissionStatus`; a denial is a result, not an error. Concurrent requests share one system prompt, and `statusUpdates()` emits the current status followed by every change, including the ones the user makes in Settings while the app is in the background.

`AppSettings.open()` opens your app's page in the Settings app. It is the only way to recover from `.denied`, because iOS shows the system prompt once.

### Bluetooth

```swift
let status = try await Permissions.bluetooth.requestAuthorization()

if status.isReady {
    // permission granted and the radio is on
}
```

`BluetoothStatus` carries two things: `permission`, the usual `PermissionStatus`, and `radio`, the state of the Bluetooth hardware (`poweredOn`, `poweredOff`, `unsupported`, and so on). Having permission is not enough to use Bluetooth, so `isReady` is true only when both are satisfied. A radio that is off is reported, not thrown, so your UI can ask the user to turn it on.

iOS has no request call for Bluetooth: the prompt appears when a `CBCentralManager` is created. The library creates it only when you call `requestAuthorization()`, so reading `status` before that never shows the prompt. `statusUpdates()` emits the radio changes too, for example when the user switches Bluetooth off in Control Center.

The library only handles the permission. Scanning and connecting are left to your own Core Bluetooth code.

### Notifications

```swift
let status = try await Permissions.notifications.requestAuthorization()
```

With no arguments it asks for alerts, sounds and badges. To choose, pass `NotificationOptions`:

```swift
let status = try await Permissions.notifications.requestAuthorization(options: [.alert, .provisional])
```

The result is a plain `PermissionStatus`. `.provisional` delivers quietly without showing a prompt and is reported as `.limited`. As with the other permissions, a denial is a result and iOS shows the prompt only once; send the user to `AppSettings.open()` after that.

When several callers request at once with the same options they share one prompt.

This module only covers the permission. Registering for remote notifications (`registerForRemoteNotifications`), handling the device token and scheduling notifications stay in your app.

### App Tracking Transparency

```swift
let status = try await Permissions.tracking.requestAuthorization()
```

iOS only shows the tracking prompt while the app is active. If you call this earlier, for example during launch, the library waits until the app becomes active instead of failing silently.

### Photos

```swift
let status = try await Permissions.photos.requestAuthorization()

if status == .limited {
    try await Permissions.photos.presentLimitedLibraryPicker()
}
```

`requestAuthorization(for:)` takes a `PhotosAccess`: `.readWrite` (the default) or `.addOnly`, which only needs permission to save. Each level has its own status. `.limited` means the user shared a selection of photos; `presentLimitedLibraryPicker()` lets them change it and throws if access is not limited. The picker uses PhotosUI.

### Face ID and Touch ID

```swift
let status = await Permissions.biometrics.status

if status.isAvailable {
    let result = try await Permissions.biometrics.authenticate(reason: "Unlock your notes")
}
```

Face ID is different from the other permissions: iOS offers no way to ask for it or to read its status. The system prompt appears the first time you authenticate. For that reason this module reports availability instead of a `PermissionStatus`: the `type` (`faceID`, `touchID`, `opticID`) and whether it is `available`, `notEnrolled`, `lockedOut`, `passcodeNotSet` or `notAvailable`. If the user denied Face ID for your app, iOS reports `notAvailable`, the same as a device without biometrics.

`authenticate(reason:)` returns a `BiometricResult` (`success`, `cancelled`, `fallbackRequested` or `failed`) and throws `PermissionError.unavailable` when biometrics cannot be used. It throws `missingUsageDescription` if `NSFaceIDUsageDescription` is missing on a Face ID device, which would otherwise fail silently.

## Using it from MVVM

Inject `LocationPermission` instead of reading `Permissions.location` inside your view model:

```swift
@MainActor @Observable
final class LocationViewModel {
    private(set) var status: LocationStatus = .notDetermined
    private(set) var lastLocation: Location?

    private let permission: LocationPermission

    init(permission: LocationPermission) {
        self.permission = permission
    }

    func requestAccess() async {
        status = (try? await permission.requestAuthorization()) ?? status
    }

    func track() async {
        do {
            for try await location in permission.updates() {
                lastLocation = location
            }
        } catch {
            return
        }
    }
}
```

Start tracking from SwiftUI with `.task { await viewModel.track() }` so it cancels when the view disappears.

`CameraPermission`, `MicrophonePermission` and `TrackingPermission` all conform to `PermissionProviding`, so one view model can serve any of them.

`@Observable` needs iOS 17. On iOS 15 and 16, use `ObservableObject` with `@Published` properties instead; the library itself supports iOS 15.

## Demo app

`Examples/SrdzPermissionsDemo` is a SwiftUI app created with Xcode 27 that uses the package through a local reference. Open `Examples/SrdzPermissionsDemo/SrdzPermissionsDemo.xcodeproj` in Xcode 27, choose your signing team if you run it on a device, and run it. It opens on a list with one row per permission, and each row pushes that permission's screen: location (requests access, fetches the current location and streams updates), camera and microphone, Bluetooth (permission and radio state), notifications, tracking, photos (with the limited selection picker) and Face ID and Touch ID. Screens offer a shortcut to Settings after a denial. The simulator has no Bluetooth hardware, so use a device to see the radio state. On the simulator, change the location with **Features > Location** or `xcrun simctl location booted set 19.4326,-99.1332`.

The app follows MVVM:

| File | Role |
|---|---|
| `LocationViewState.swift` | Explicit state and display-ready view data |
| `LocationViewModel.swift` | `@Observable` model that owns tasks and talks to `LocationPermission` |
| `LocationView.swift` | Renders state and forwards user intents |
| `LocationAssembly.swift` | Wires the live dependency |

The package itself builds with any Xcode that supports Swift 6; only the demo project needs Xcode 27.

`Examples/SrdzPermissionsXCFrameworkDemo` is the same app, MVVM included, but it integrates the library through the XCFrameworks instead of Swift Package Manager. Run `./Scripts/build-xcframework.sh` first: the project references `build/xcframeworks/`, which is not committed, so its frameworks show as missing until you build them.

## Documentation

Every public declaration has DocC documentation. In Xcode, open the package and choose **Product > Build Documentation**, or run `xcodebuild docbuild -scheme SrdzPermissions-Package -destination 'generic/platform=iOS Simulator'`.

## Testing

`SrdzPermissionsTesting` provides `FakeLocationProvider`, `FakePermissionProvider` (camera, microphone and tracking), `FakeBluetoothProvider`, `FakeNotificationProvider`, `FakePhotosProvider` and `FakeBiometricsProvider`:

```swift
import SrdzPermissionsTesting

let fake = FakeLocationProvider(
    status: LocationStatus(permission: .authorized, access: .whenInUse),
    locations: [Location(latitude: 19.4326, longitude: -99.1332)]
)
let viewModel = LocationViewModel(permission: LocationPermission(provider: fake))

let camera = CameraPermission(provider: FakePermissionProvider(authorizationResult: .authorized))
```

## Architecture

```
LocationPermission        public facade, delegates only
  LocationProviding       public protocol, the seam for fakes
    LocationService       actor that owns all mutable state
      LocationBackend     internal protocol
        CoreLocationBackend   CLLocationManager adapter (iOS)

CameraPermission, MicrophonePermission    public facades
  PermissionProviding                     public protocol (Core), the seam for fakes
    AuthorizationService                    Core actor; also used by TrackingPermission
      CaptureBackend                      internal protocol
        AVCaptureBackend                  AVCaptureDevice adapter (iOS)

BluetoothPermission       public facade
  BluetoothProviding      public protocol, the seam for fakes
    BluetoothService      actor that waits for the manager's first report
      BluetoothBackend    internal protocol
        CoreBluetoothBackend  CBCentralManager adapter (iOS)

NotificationPermission    public facade
  NotificationProviding   public protocol, the seam for fakes
    NotificationService   delegates to the shared service in Core
      NotificationBackend internal protocol
        UserNotificationsBackend  UNUserNotificationCenter adapter (iOS)
```

- `SrdzPermissionsCore` holds the shared types: `PermissionStatus`, `PermissionError`, `PermissionProviding` and `AppSettings`, plus the internal `AuthorizationService`, an actor that coalesces concurrent requests, supports cancellation and publishes status changes. Camera, microphone, notifications, tracking and photos are thin layers over it.
- Each permission lives in its own module, so apps link only what they use.
- Services are tested against fake backends, without Core Location or AVFoundation.

## Roadmap

- Contacts and calendar
- Upgrade from `.whenInUse` to `.always` with a prompt

## Contributing

Issues and pull requests are welcome. `AGENTS.md` describes the project conventions, and it works for humans too.

```bash
swift test
```

## License

Released under the MIT License. See [LICENSE](LICENSE).

The AI agent skills in `.agents/skills` are third-party works under their own MIT licenses. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
