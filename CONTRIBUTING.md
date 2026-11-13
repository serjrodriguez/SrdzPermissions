# Contributing to SrdzPermissions

Thanks for helping. This page explains how changes move through the repository. For the code conventions and the architecture, read [AGENTS.md](AGENTS.md); it is written for agents but works for humans too.

## Branch flow

```
feature/*  ──pull request──▶  develop  ──release pull request──▶  main  ──▶  tag vX.Y.Z
```

- `main` holds released code. Nobody pushes to it: it only receives the release pull request from `develop`.
- `develop` is the integration branch. It also takes no direct pushes.
- Every contribution starts from the latest `develop` on its own branch and goes back to `develop` through a pull request.

Branch names use a prefix that says what they are: `feature/`, `fix/`, `docs/` or `chore/`, for example `feature/contacts-permission`.

## Your first change

1. Fork the repository, or clone it if you have access, and branch from `develop`:

   ```bash
   git switch develop
   git pull
   git switch -c feature/my-change
   ```

2. Make the change, with tests. Run them before pushing:

   ```bash
   swift test
   ```

3. Push the branch and open a pull request **into `develop`**.
4. Wait for the checks below to pass, then address review comments. Squash or merge as the maintainer asks.

## Checks every pull request must pass

Pull requests run `.github/workflows/ci.yml`. All four jobs must be green before merging:

| Job | What it checks |
|---|---|
| `tests` | `swift test` on macOS |
| `ios-build` | The package compiles for the iOS Simulator, where the `#if os(iOS)` code is built |
| `tsan` | The tests pass under Thread Sanitizer, to catch data races |
| `docs` | DocC builds with zero warnings |

You can run the same commands locally:

```bash
swift test --sanitize=thread
```

```bash
xcodebuild build -scheme SrdzPermissions-Package -destination 'generic/platform=iOS Simulator'
```

```bash
xcodebuild docbuild -scheme SrdzPermissions-Package -destination 'generic/platform=iOS Simulator'
```

## Code rules

- Swift 6 language mode with strict concurrency. No warnings.
- Tests use Swift Testing. Wait on observable state, never on fixed sleeps. New behavior needs a test, and lifecycle-sensitive code needs a lifetime test.
- No comments in code. The only exception is `///` DocC documentation on `public` declarations, which every public declaration must have. Names and tests carry the intent.
- Adding a permission follows the module layout in `AGENTS.md`: `Models/`, `API/`, `Internal/Service/`, `Internal/Backend/`, a test target, a fake in `SrdzPermissionsTesting`, an entry in the umbrella, the README and the `INSTALL.md` table.
- Commit messages are short, in the imperative: "Add the contacts permission".
- The demo projects reference a development team that is local to each machine. Never commit changes to `DEVELOPMENT_TEAM` in the `project.xcproj` files. Stage files by name instead of using `git add .`.

## Releases (maintainers)

1. Collect the changes in `develop`.
2. Bump `VERSION` (for example `0.2.0`) in `develop`.
3. Open a pull request from `develop` into `main`. It runs `ci.yml` and `release-check.yml`, which also verifies that the pull request comes from `develop`, that `VERSION` is a valid version whose tag does not exist yet, and that the XCFrameworks and release package build.
4. Merge it. `release.yml` builds the artifacts, creates the tag `vX.Y.Z` on the merge commit and publishes a GitHub release with the zips and `checksums.txt` attached.
5. Merge `main` back into `develop` so both branches share the release commit.

The tag always points at a commit of `main`, so Swift Package Manager builds from source. If `VERSION` was not bumped, the release workflow finds the existing tag and does nothing.
