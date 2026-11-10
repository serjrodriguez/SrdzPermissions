# AGENTS.md
## What this is

`SrdzPermissions`: a Swift package that wraps iOS permission APIs (location first; camera, notifications, etc. planned) behind `async/await`, `AsyncStream` and actors. Public repo used as a portfolio piece, so API docs (`///`) and clean history matter. Owner GitHub handle: `serjrodriguez`. Naming: package/module prefix is `Srdz`; public types have **no** prefix (`LocationPermission`, `PermissionStatus`).

The owner is learning while building: explain non-obvious decisions briefly and keep changes small and reviewable.

## Commands

```bash
swift build                      # builds on the macOS host (macOS 12 is only declared for fast local testing)
swift test                       # runs all Swift Testing suites
swift test --filter WaitersTests # run one suite (or `--filter WaitersTests/cancelResumes...` for one test)
```

CoreLocation-backed code must additionally be checked against iOS: build the `SrdzPermissions-Package` scheme with destination "Any iOS Simulator Device" in Xcode (or `xcodebuild`). Tests use Swift Testing (`import Testing`, `@Test`, `#expect`), not XCTest.

## Architecture

Multi-target package (`Package.swift`, tools 6.0 → Swift 6 language mode, strict concurrency on):

- `SrdzPermissionsCore` — shared, framework-free primitives: `PermissionStatus`, `PermissionError`, `InfoPlistValidator`, `Waiters`.
- `SrdzPermissionsLocation` — location permission: public value types (`Location`, `LocationStatus`, `LocationAccess`, `LocationUpdateOptions`) plus, in `Internal/`, the implementation. It `@_exported import`s Core so consumers of this product don't need a second import.
- `SrdzPermissions` — umbrella product that depends on all permission modules and hosts the `Permissions` entry point (`Permissions.location`, iOS only).
- `SrdzPermissionsTesting` — public test-support product (`FakeLocationProvider`) so consumers can fake the facade in their own tests. It is the only non-test code that exists for tests; keep every other test helper under `Tests/`.
- One **library product per permission** on purpose: apps link only the Apple frameworks they use (avoids App Review / Info.plist issues and binary bloat). Future modules follow the same shape (`SrdzPermissionsCamera`, `...Notifications`).

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

Distribution targets: SPM (primary), local package, and XCFramework per module (script planned in `Scripts/`, built with `BUILD_LIBRARY_FOR_DISTRIBUTION=YES`). CocoaPods is out of scope.

## Repo conventions

- Commits: this repo's local git email is the GitHub noreply address (public repo; never switch it to a real email).
- File headers use the form `Created by Sergio Rodriguez on dd/MM/yy` (set via the global Xcode template).
- `.swiftpm/` and Xcode user state are git-ignored.
- No README or LICENSE yet; both are planned once the location MVP works.

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
