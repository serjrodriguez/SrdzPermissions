# AGENTS.md
## What this is

`SrdzPermissions`: a Swift package that wraps iOS permission APIs (location, camera, microphone and Bluetooth so far; notifications, etc. planned) behind `async/await`, `AsyncStream` and actors. Public repo used as a portfolio piece, so API docs (`///`) and clean history matter. Owner GitHub handle: `serjrodriguez`. Naming: package/module prefix is `Srdz`; public types have **no** prefix (`LocationPermission`, `PermissionStatus`).

The owner is learning while building: explain non-obvious decisions briefly and keep changes small and reviewable.

## Commands

```bash
swift build                      # builds on the macOS host (macOS 12 is only declared for fast local testing)
swift test                       # runs all Swift Testing suites
swift test --filter WaitersTests # run one suite (or `--filter WaitersTests/cancelResumes...` for one test)
```

The demo app lives in `Examples/SrdzPermissionsDemo`. It was created with Xcode 27 tooling (`XcodeNewProject`), so its project file is the new text format `project.xcproj` and needs Xcode 27 to open. It uses MVVM under `SrdzPermissionsDemo/Location/` (state, view model, view, assembly) and links the package by the local path `../..` (never a path that includes the repo folder name). Prefer the Xcode plugin tools (`XcodeWrite`, `UpdateTargetBuildSetting`, `AddInfoPlist`) over editing the project file by hand; there is no tool to add a package dependency, so that step is done in the Xcode UI. A second demo, `Examples/SrdzPermissionsXCFrameworkDemo`, has the same MVVM code but links the XCFrameworks from `build/xcframeworks/` (run the script first; nothing built is committed). In its `project.xcproj` a framework is a `files` entry such as `{ "path": "../../build/xcframeworks/SrdzPermissionsCore.xcframework", "target-membership": [ "SrdzPermissionsXCFrameworkDemo/frameworks" ] }`, and the frameworks are static, so nothing is embedded. Both demos have three tabs: Location (`Location/`), Capture (`Capture/`, camera and microphone sharing one view model type) and Bluetooth (`Bluetooth/`). Keep both demos in sync when either UI changes, and add the matching `INFOPLIST_KEY_NS…UsageDescription` settings and, in the XCFramework demo, the framework entries when a module is added.

Build for the simulator with `xcodebuild -project Examples/SrdzPermissionsDemo/SrdzPermissionsDemo.xcodeproj -scheme SrdzPermissionsDemo -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`.

CoreLocation-backed code must additionally be checked against iOS: build the `SrdzPermissions-Package` scheme with destination "Any iOS Simulator Device" in Xcode (or `xcodebuild`). Tests use Swift Testing (`import Testing`, `@Test`, `#expect`), not XCTest.

## Architecture

Multi-target package (`Package.swift`, tools 6.0 → Swift 6 language mode, strict concurrency on):

- `SrdzPermissionsCore` — shared, framework-free primitives: `PermissionStatus`, `PermissionError`, `InfoPlistValidator`, `Waiters`, `AppSettings`.
- `SrdzPermissionsLocation` — location permission: public value types (`Location`, `LocationStatus`, `LocationAccess`, `LocationUpdateOptions`) plus, in `Internal/`, the implementation. It `@_exported import`s Core so consumers of this product don't need a second import.
- `SrdzPermissions` — umbrella product that depends on all permission modules and hosts the `Permissions` entry point (`Permissions.location`, `.camera`, `.microphone`, `.bluetooth`, iOS only).
- `SrdzPermissionsCamera` — camera and microphone permission (`CameraPermission`, `MicrophonePermission`, both conforming to `CapturePermissionProviding`). Status is the shared `PermissionStatus`; there is no module-specific status type. `AVCaptureBackend` is `#if os(iOS)` and re-evaluates the status on `didBecomeActive`, because AVFoundation has no authorization callback. Core also holds `AppSettings.open()` (iOS only) to leave `.denied`.
- `SrdzPermissionsBluetooth` — Bluetooth permission (`BluetoothPermission`, `BluetoothStatus` = shared `PermissionStatus` plus a `BluetoothRadioState`, because permission and radio power are different things). iOS has no request API: the prompt is triggered by creating a `CBCentralManager`, so `CoreBluetoothBackend` creates it only in `startMonitoring()`, and `BluetoothService` calls that from `requestAuthorization()` or when the permission is already `.authorized`; never for `.notDetermined` in `status`, or reading the status would prompt. `BluetoothService` waits for status with predicates (`waitForStatus`) because the first delegate callback carries the radio state.
- `SrdzPermissionsTesting` — public test-support product (`FakeLocationProvider`, `FakeCapturePermissionProvider`, `FakeBluetoothProvider`) so consumers can fake the facade in their own tests. It is the only non-test code that exists for tests; keep every other test helper under `Tests/`.
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

## Repo conventions

- Commits: this repo's local git email is the GitHub noreply address (public repo; never switch it to a real email).
- File headers use the form `Created by Sergio Rodriguez on dd/MM/yy` (set via the global Xcode template).
- `.swiftpm/` and Xcode user state are git-ignored.
- Keep `README.md` in sync with the public API and the roadmap; the XCFramework build script is still pending, so the README must not claim it exists.

## Location module specifics

- `LocationService` (actor) is the reference implementation: lazy backend creation (`makeBackend` factory, because `CoreLocationBackend` is `@MainActor`), a single event-consuming task, `Waiters` for coalescing, and `outcomeSequence` so a waiter notices results that arrived while it was suspended in a backend call (actor reentrancy).
- Streams use a "serving task" per stream: `onTermination` cancels the task, the task parks in `Task.sleep(.max)` and unregisters itself on cancellation. This avoids registration/termination races without tombstones.
- `CoreLocationBackend` is `#if os(iOS)`; `LocationPermission.live` and `Permissions.location` exist only on iOS. All other logic compiles and is tested on macOS with `FakeLocationBackend`.
- Tests wait on observable state (`waitUntil`, `subscriberCount`) instead of sleeping. A stream that is still referenced keeps tracking alive: create streams inside the task that consumes them.

## Code style

- Do not write comments in code (no `//`, `///` or `// MARK:`). Names and tests carry the intent. Keep the Xcode file header and the `// swift-tools-version` line in `Package.swift`.

## Module folder layout

Each permission module groups files as `Models/` (public value types), `API/` (facade, provider protocol, `+Live`), `Internal/Service/` (actor) and `Internal/Backend/` (backend protocol and framework adapter). Copy this layout for new permissions, but only add a service/backend split when the framework needs delegates or state; frameworks with native `async` APIs can use a thin service. Do not introduce a generic `Permission` protocol until a second permission exists.

## Agent skills

Shared skills live in `.agents/skills/` and are exposed to Claude Code through the `.claude/skills` symlink. They are third-party MIT-licensed works; sources, authors and license texts are in `THIRD_PARTY_NOTICES.md`.

- `swift-concurrency-pro` — review async/await, actors and streams.
- `swift-api-design-guidelines-skill` — review public API naming and labels.
- `swift-architecture-skill` — architecture guidance and review checklists.
