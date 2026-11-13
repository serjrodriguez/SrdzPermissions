# AGENTS.md
## What this is

`SrdzPermissions`: a Swift package that wraps iOS permission APIs (location, camera, microphone, Bluetooth, notifications, tracking, photos and biometrics so far; contacts, calendar, etc. planned) behind `async/await`, `AsyncStream` and actors. Public repo used as a portfolio piece, so API docs (`///`) and clean history matter. Owner GitHub handle: `serjrodriguez`. Naming: package/module prefix is `Srdz`; public types have **no** prefix (`LocationPermission`, `PermissionStatus`).

The owner is learning while building: explain non-obvious decisions briefly and keep changes small and reviewable.

## Commands

```bash
swift build                      # builds on the macOS host (macOS 12 is only declared for fast local testing)
swift test                       # runs all Swift Testing suites
swift test --filter WaitersTests # run one suite (or `--filter WaitersTests/cancelResumes...` for one test)
```

The demo app lives in `Examples/SrdzPermissionsDemo`. It was created with Xcode 27 tooling (`XcodeNewProject`), so its project file is the new text format `project.xcproj` and needs Xcode 27 to open. It uses MVVM under `SrdzPermissionsDemo/Location/` (state, view model, view, assembly) and links the package by the local path `../..` (never a path that includes the repo folder name). Prefer the Xcode plugin tools (`XcodeWrite`, `UpdateTargetBuildSetting`, `AddInfoPlist`) over editing the project file by hand; there is no tool to add a package dependency, so that step is done in the Xcode UI. A second demo, `Examples/SrdzPermissionsXCFrameworkDemo`, has the same MVVM code but links the XCFrameworks from `build/xcframeworks/` (run the script first; nothing built is committed). In its `project.xcproj` a framework is a `files` entry such as `{ "path": "../../build/xcframeworks/SrdzPermissionsCore.xcframework", "target-membership": [ "SrdzPermissionsXCFrameworkDemo/frameworks" ] }`, and the frameworks are static, so nothing is embedded. Both demos open on `Home/PermissionsHomeView`, a list driven by the `DemoFeature` enum that pushes one screen per permission (`Location/`, `Capture/`, `Bluetooth/`, `Notifications/`, `Tracking/`, `Photos/`, `Biometrics/`). Screens do not own a `NavigationStack`; the home view does. `Shared/` has the `PermissionViewModel` and `PermissionSection` used by every `PermissionProviding` (camera, microphone, tracking). To add a permission, add a `DemoFeature` case and its destination. Keep both demos in sync when either UI changes, and add the matching `INFOPLIST_KEY_NS…UsageDescription` settings and, in the XCFramework demo, the framework entries when a module is added.

Build for the simulator with `xcodebuild -project Examples/SrdzPermissionsDemo/SrdzPermissionsDemo.xcodeproj -scheme SrdzPermissionsDemo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`.

CoreLocation-backed code must additionally be checked against iOS: build the `SrdzPermissions-Package` scheme with destination "Any iOS Simulator Device" in Xcode (or `xcodebuild`). Tests use Swift Testing (`import Testing`, `@Test`, `#expect`), not XCTest.

## Architecture

Multi-target package (`Package.swift`, tools 6.0 → Swift 6 language mode, strict concurrency on):

- `SrdzPermissionsCore` — shared, framework-free primitives: `PermissionStatus`, `PermissionError`, `InfoPlistValidator`, `Waiters`, `AppSettings`, `PermissionProviding` (the public seam for permissions with no arguments) and `AuthorizationService<Scope>` and `ApplicationActivity` (package-internal; see below).
- `SrdzPermissionsLocation` — location permission: public value types (`Location`, `LocationStatus`, `LocationAccess`, `LocationUpdateOptions`) plus, in `Internal/`, the implementation. It `@_exported import`s Core so consumers of this product don't need a second import.
- `SrdzPermissions` — umbrella product that depends on all permission modules and hosts the `Permissions` entry point (`Permissions.location`, `.camera`, `.microphone`, `.bluetooth`, `.notifications`, `.tracking`, `.photos`, `.biometrics`, iOS only).
- `SrdzPermissionsCamera` — camera and microphone permission (`CameraPermission`, `MicrophonePermission`, both conforming to `PermissionProviding`). Status is the shared `PermissionStatus`; there is no module-specific status type. `AVCaptureBackend` is `#if os(iOS)` and re-evaluates the status on `didBecomeActive`, because AVFoundation has no authorization callback. Core also holds `AppSettings.open()` (iOS only) to leave `.denied`.
- `SrdzPermissionsBluetooth` — Bluetooth permission (`BluetoothPermission`, `BluetoothStatus` = shared `PermissionStatus` plus a `BluetoothRadioState`, because permission and radio power are different things). iOS has no request API: the prompt is triggered by creating a `CBCentralManager`, so `CoreBluetoothBackend` creates it only in `startMonitoring()`, and `BluetoothService` calls that from `requestAuthorization()` or when the permission is already `.authorized`; never for `.notDetermined` in `status`, or reading the status would prompt. `BluetoothService` waits for status with predicates (`waitForStatus`) because the first delegate callback carries the radio state.
- `SrdzPermissionsNotifications` — notification permission (`NotificationPermission`, `NotificationOptions`). Deliberately minimal: it returns the shared `PermissionStatus` (`.provisional` maps to `.limited`), defaults to `.standard` options, needs no Info.plist key, and does not cover remote registration or scheduling. 
- `SrdzPermissionsTracking` — App Tracking Transparency, a `PermissionProviding`. The backend waits until the app is active before requesting, because iOS silently ignores the prompt otherwise.
- `SrdzPermissionsPhotos` — `PhotosPermission`, whose calls take a `PhotosAccess` (`.readWrite` or `.addOnly`); each level has its own status and Info.plist key. `.limited` is a normal result and `presentLimitedLibraryPicker()` (PhotosUI, `PHPhotoLibrary.presentLimitedLibraryPicker(from:completionHandler:)`) only works when access is limited.
- `SrdzPermissionsBiometrics` — `BiometricsPermission`. Not a `PermissionStatus`: iOS exposes no status or request API for Face ID, the prompt appears on the first `evaluatePolicy`, and a denial surfaces as `biometryNotAvailable`. So it reports `BiometricStatus` (type + availability) and `authenticate(reason:)`. `NSFaceIDUsageDescription` is validated only when the type is `.faceID`. `LocalAuthenticationBackend.evaluate` cancels through `withTaskCancellationHandler` calling `LAContext.invalidate()`, which dismisses the system prompt; the context is a `nonisolated(unsafe)` local because `LAContext` is not `Sendable` and `invalidate()` is the only call made from the cancellation handler. This is the single deliberate use of `nonisolated(unsafe)`.
- `AuthorizationService<Scope>` (Core, `package`) is the shared implementation behind camera, microphone, notifications, tracking and photos: it coalesces concurrent requests per scope with `Waiters`, supports cancellation, maps errors to `PermissionError` and publishes status changes from a signal stream. A permission module supplies closures (read status, perform the request, change signals) and an optional `validate` hook for its Info.plist check, which runs before anything else. For `Unscoped` it already conforms to `PermissionProviding`, so Camera, Microphone and Tracking hand it straight to their facade through `makeCaptureService` / `makeTrackingService`; Notifications and Photos keep a small adapter because their calls take an argument. `ApplicationActivity` (Core, iOS) holds the `didBecomeActive` signal stream and `waitUntilActive()` that those backends share; do not copy them again. Use it for any new permission that follows the "read status / request / observe" shape; `Unscoped` is the scope for permissions without parameters. Location and Bluetooth keep their own services because they are delegate-driven; they share a skeleton (lazy backend, one event task, waiters) that is not worth abstracting with only two cases, so reconsider it when a third delegate-driven permission appears.
- `SrdzPermissionsTesting` — public test-support product (`FakeLocationProvider`, `FakePermissionProvider`, `FakeBluetoothProvider`, `FakeNotificationProvider`, `FakePhotosProvider`, `FakeBiometricsProvider`) so consumers can fake the facade in their own tests. It is the only non-test code that exists for tests; keep every other test helper under `Tests/`.
- One **library product per permission** on purpose: apps link only the Apple frameworks they use (avoids App Review / Info.plist issues and binary bloat). Future modules follow the same shape.

Layers inside each permission module (implemented for Location — copy this shape for new permissions):

1. Public **facade** struct (e.g. `LocationPermission`) that only delegates to a `…Providing` protocol.
2. Internal **actor** service holding all mutable state, coalescing concurrent callers via `Waiters`, exposing `AsyncStream`/`AsyncThrowingStream` for updates.
3. Internal **backend** protocol + the real framework adapter (e.g. a `@MainActor` `CLLocationManager` delegate proxy that forwards events as an `AsyncStream` of Sendable events). Tests inject a fake backend, so service logic is testable without CoreLocation.

Design rules to preserve:

- **Denied is not an error**: `request…` returns a status (`.denied` is a valid result); `PermissionError` is only for system/config failures (missing Info.plist key, services disabled, timeout, `notAuthorized` when using a feature without permission).
- Public API uses own `Sendable` value types, never `CLLocation` / `CLAuthorizationStatus`.
- Cross-module internals use `package` access (`Waiters`, `InfoPlistValidator`), not `public`, so they stay out of the consumer-facing API. Anything consumers must construct needs an explicit `public init`.
- `Waiters` stores `CheckedContinuation`s and is **not thread-safe**: only use it as private state of an actor. Each continuation must be resumed exactly once (it clears before resuming; `cancel(id)` removes then resumes).
- Public APIs should use `TimeInterval` rather than `Duration` for timeouts (iOS 15 minimum; `Duration` needs iOS 16).

Distribution targets: SPM (primary), local package, and one static XCFramework per module built by `Scripts/build-xcframework.sh` (`./Scripts/build-xcframework.sh [scheme...]`, output in `build/xcframeworks/`, git-ignored). CocoaPods is out of scope.

XCFramework design notes: they are static frameworks, one per module, because Xcode does not add a library XCFramework's `Headers` to the Swift module search path and because a dynamic product would duplicate `SrdzPermissionsCore` inside every module that uses it. The script archives the umbrella scheme (plus `SrdzPermissionsTesting`) and splits the resulting objects and `.swiftinterface` files by module, so a new permission module is packaged automatically once the umbrella depends on it. Consumers must link the whole dependency chain (Location needs Core). Slices: device `arm64 arm64e`, simulator `arm64 x86_64`, minimum iOS 15.0 (checked with `lipo` and `vtool`); `arm64e` is included for consumers that build for it and is ignored by `arm64` apps. It was verified by building executables against the XCFrameworks as SwiftPM `binaryTarget`s for device and simulator, not by dragging them into an Xcode project.

Release packaging: `Scripts/package-release.sh <version> [--skip-build]` (it runs `build-xcframework.sh` unless told otherwise) writes `build/release/` (git-ignored): the ten zips, `checksums.txt`, `SrdzPermissions-all.zip` (frameworks, the Testing framework apart, and `INSTALL.md` rendered from `Scripts/templates/INSTALL.md`), a `Package.swift` made of `binaryTarget`s for the release tag, and `local-package/`, the same manifest with `path:` targets used to verify it. Every product chains `SrdzPermissionsCore` with its module, which is how SwiftPM pulls the dependency in automatically; the `Testing` product lists every module it fakes. Verified with throwaway consumer packages that depend on `local-package` and build for the simulator and a device: one using only `SrdzPermissionsLocation` compiled just Core and Location, and another used `SrdzPermissions` plus `SrdzPermissionsTesting`. Publishing is automated: merging the release pull request into `main` runs `.github/workflows/release.yml`, which reads `VERSION`, runs this script, and creates the tag `v<VERSION>` on the merge commit with a GitHub release that attaches every zip and `checksums.txt`. The tag always points at `main`, so Swift Package Manager builds from source; the binary `Package.swift` is a verified build output that is not published yet. Keep the module list in the script, in `INSTALL.md` and in the README table in sync when a permission module is added.

## Repo conventions

- Commits: this repo's local git email is the GitHub noreply address (public repo; never switch it to a real email).
- File headers use the form `Created by Sergio Rodriguez on dd/MM/yy` (set via the global Xcode template).
- `.swiftpm/` and Xcode user state are git-ignored.
- Keep `README.md` in sync with the public API and the roadmap; the XCFramework build script is still pending, so the README must not claim it exists.

## Location module specifics

- `currentLocation(timeout:)` caps huge timeouts and treats NaN or non-positive ones as zero in `LocationService.nanoseconds(from:)`; converting `.infinity` to `UInt64` traps, so never reintroduce a raw conversion.
- `LocationService` (actor) is the reference implementation: lazy backend creation (`makeBackend` factory, because `CoreLocationBackend` is `@MainActor`), a single event-consuming task, `Waiters` for coalescing, and `outcomeSequence` so a waiter notices results that arrived while it was suspended in a backend call (actor reentrancy).
- Streams use a "serving task" per stream: `onTermination` cancels the task, the task parks in `Task.sleep(.max)` and unregisters itself on cancellation. This avoids registration/termination races without tombstones.
- `CoreLocationBackend` is `#if os(iOS)`; `LocationPermission.live` and `Permissions.location` exist only on iOS. All other logic compiles and is tested on macOS with `FakeLocationBackend`.
- Tests wait on observable state (`waitUntil`, `subscriberCount`) instead of sleeping. Each test target has its own `waitUntil`: it polls the condition (yielding first, then 1 ms sleeps) for up to five seconds and records an `Issue` if it is never met, so a missed wait fails loudly instead of letting the test continue. Lifetime tests (`*LifetimeTests`) hold a `weak` reference and check that services, backends and streams are released. A stream that is still referenced keeps tracking alive: create streams inside the task that consumes them.

## Code style

- Do not write comments in code (no `//` or `// MARK:`, and no `///` on internal, package or private declarations). Names and tests carry the intent. The one exception is `///` DocC documentation on `public` declarations, which every public declaration has. Keep the Xcode file header and the `// swift-tools-version` line in `Package.swift`.

## Module folder layout

Each permission module groups files as `Models/` (public value types), `API/` (facade, provider protocol, `+Live`), `Internal/Service/` (actor) and `Internal/Backend/` (backend protocol and framework adapter). Copy this layout for new permissions, but only add a service/backend split when the framework needs delegates or state; frameworks with native `async` APIs can use a thin service. Do not introduce a generic `Permission` protocol until a second permission exists.

## Agent skills

Shared skills live in `.agents/skills/` and are exposed to Claude Code through the `.claude/skills` symlink. They are third-party MIT-licensed works; sources, authors and license texts are in `THIRD_PARTY_NOTICES.md`.

- `swift-concurrency-pro` — review async/await, actors and streams.
- `swift-api-design-guidelines-skill` — review public API naming and labels.
- `swift-architecture-skill` — architecture guidance and review checklists.
