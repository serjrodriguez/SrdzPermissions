# SrdzPermissions

A Swift package for requesting iOS permissions with Swift Concurrency: `async/await`, `AsyncStream` and actors. One consistent API on top of frameworks that mix delegates, completion handlers and async methods.

Location is available today. Camera, notifications and more are planned.

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
| Everything, with the `Permissions` entry point | `SrdzPermissionsCore`, `SrdzPermissionsLocation` and `SrdzPermissions` |
| Fakes for tests | `SrdzPermissionsTesting`, in test targets only |

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

`@Observable` needs iOS 17. On iOS 15 and 16, use `ObservableObject` with `@Published` properties instead; the library itself supports iOS 15.

## Demo app

`Examples/SrdzPermissionsDemo` is a SwiftUI app created with Xcode 27 that uses the package through a local reference. Open `Examples/SrdzPermissionsDemo/SrdzPermissionsDemo.xcodeproj` in Xcode 27, choose your signing team if you run it on a device, and run it. It requests access, fetches the current location and streams updates. On the simulator, change the location with **Features > Location** or `xcrun simctl location booted set 19.4326,-99.1332`.

The app follows MVVM:

| File | Role |
|---|---|
| `LocationViewState.swift` | Explicit state and display-ready view data |
| `LocationViewModel.swift` | `@Observable` model that owns tasks and talks to `LocationPermission` |
| `LocationView.swift` | Renders state and forwards user intents |
| `LocationAssembly.swift` | Wires the live dependency |

The package itself builds with any Xcode that supports Swift 6; only the demo project needs Xcode 27.

`Examples/SrdzPermissionsXCFrameworkDemo` is the same app, MVVM included, but it integrates the library through the XCFrameworks instead of Swift Package Manager. Run `./Scripts/build-xcframework.sh` first: the project references `build/xcframeworks/`, which is not committed, so its frameworks show as missing until you build them.

## Testing

`SrdzPermissionsTesting` provides `FakeLocationProvider`:

```swift
import SrdzPermissionsTesting

let fake = FakeLocationProvider(
    status: LocationStatus(permission: .authorized, access: .whenInUse),
    locations: [Location(latitude: 19.4326, longitude: -99.1332)]
)
let viewModel = LocationViewModel(permission: LocationPermission(provider: fake))
```

## Architecture

```
LocationPermission        public facade, delegates only
  LocationProviding       public protocol, the seam for fakes
    LocationService       actor that owns all mutable state
      LocationBackend     internal protocol
        CoreLocationBackend   CLLocationManager adapter (iOS)
```

- `SrdzPermissionsCore` holds the shared types: `PermissionStatus` and `PermissionError`.
- Each permission lives in its own module, so apps link only what they use.
- The service is tested against a fake backend, without Core Location.

## Roadmap

- Camera and microphone
- Notifications
- Photos, contacts, calendar
- Upgrade from `.whenInUse` to `.always` with a prompt

## Contributing

Issues and pull requests are welcome. `AGENTS.md` describes the project conventions, and it works for humans too.

```bash
swift test
```

## License

Released under the MIT License. See [LICENSE](LICENSE).

The AI agent skills in `.agents/skills` are third-party works under their own MIT licenses. See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
