#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "usage: Scripts/package-release.sh <version> [--skip-build]" >&2
    exit 1
fi
SKIP_BUILD=0
if [ "${2:-}" = "--skip-build" ]; then
    SKIP_BUILD=1
fi

REPOSITORY="serjrodriguez/SrdzPermissions"
PERMISSIONS=(Location Camera Bluetooth Notifications Tracking Photos Biometrics)
FRAMEWORKS_DIR="$ROOT/build/xcframeworks"
OUTPUT_DIR="$ROOT/build/release"

if [ "$SKIP_BUILD" -eq 0 ]; then
    "$ROOT/Scripts/build-xcframework.sh"
fi

MODULES=(SrdzPermissionsCore)
for permission in "${PERMISSIONS[@]}"; do
    MODULES+=("SrdzPermissions$permission")
done
MODULES+=(SrdzPermissions SrdzPermissionsTesting)

for module in "${MODULES[@]}"; do
    for required in "$module.xcframework" "$module.xcframework.zip" "$module.xcframework.zip.checksum"; do
        if [ ! -e "$FRAMEWORKS_DIR/$required" ]; then
            echo "error: $FRAMEWORKS_DIR/$required is missing; run Scripts/build-xcframework.sh first" >&2
            exit 1
        fi
    done
done

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

: > "$OUTPUT_DIR/checksums.txt"
for module in "${MODULES[@]}"; do
    cp "$FRAMEWORKS_DIR/$module.xcframework.zip" "$OUTPUT_DIR/"
    echo "$(cat "$FRAMEWORKS_DIR/$module.xcframework.zip.checksum")  $module.xcframework.zip" >> "$OUTPUT_DIR/checksums.txt"
done

echo "==> building SrdzPermissions-all.zip"
STAGE="$OUTPUT_DIR/stage/SrdzPermissions-$VERSION"
mkdir -p "$STAGE/Frameworks" "$STAGE/Testing"
for module in "${MODULES[@]}"; do
    if [ "$module" = "SrdzPermissionsTesting" ]; then
        cp -R "$FRAMEWORKS_DIR/$module.xcframework" "$STAGE/Testing/"
    else
        cp -R "$FRAMEWORKS_DIR/$module.xcframework" "$STAGE/Frameworks/"
    fi
done
sed "s/{{VERSION}}/$VERSION/g" "$ROOT/Scripts/templates/INSTALL.md" > "$STAGE/INSTALL.md"
(cd "$OUTPUT_DIR/stage" && ditto -c -k --norsrc --noextattr --keepParent "SrdzPermissions-$VERSION" "$OUTPUT_DIR/SrdzPermissions-all.zip")
rm -rf "$OUTPUT_DIR/stage"

write_manifest() {
    local destination="$1" mode="$2"
    {
        echo "// swift-tools-version: 6.0"
        echo
        echo "import PackageDescription"
        echo
        echo "let package = Package("
        echo "    name: \"SrdzPermissions\","
        echo "    platforms: [.iOS(.v15)],"
        echo "    products: ["

        all_targets="\"SrdzPermissionsCore\""
        for permission in "${PERMISSIONS[@]}"; do
            all_targets="$all_targets, \"SrdzPermissions$permission\""
        done
        echo "        .library(name: \"SrdzPermissions\", targets: [$all_targets, \"SrdzPermissions\"]),"
        for permission in "${PERMISSIONS[@]}"; do
            echo "        .library(name: \"SrdzPermissions$permission\", targets: [\"SrdzPermissionsCore\", \"SrdzPermissions$permission\"]),"
        done
        echo "        .library(name: \"SrdzPermissionsTesting\", targets: [$all_targets, \"SrdzPermissionsTesting\"]),"

        echo "    ],"
        echo "    targets: ["
        for module in "${MODULES[@]}"; do
            if [ "$mode" = "url" ]; then
                checksum="$(cat "$FRAMEWORKS_DIR/$module.xcframework.zip.checksum")"
                echo "        .binaryTarget("
                echo "            name: \"$module\","
                echo "            url: \"https://github.com/$REPOSITORY/releases/download/$VERSION/$module.xcframework.zip\","
                echo "            checksum: \"$checksum\""
                echo "        ),"
            else
                echo "        .binaryTarget(name: \"$module\", path: \"$module.xcframework\"),"
            fi
        done
        echo "    ]"
        echo ")"
    } > "$destination"
}

echo "==> writing the binary manifest"
write_manifest "$OUTPUT_DIR/Package.swift" url

LOCAL_DIR="$OUTPUT_DIR/local-package"
mkdir -p "$LOCAL_DIR"
for module in "${MODULES[@]}"; do
    cp -R "$FRAMEWORKS_DIR/$module.xcframework" "$LOCAL_DIR/"
done
write_manifest "$LOCAL_DIR/Package.swift" path

echo
echo "Release $VERSION is ready in $OUTPUT_DIR:"
ls -1 "$OUTPUT_DIR" | sed 's/^/    /'
