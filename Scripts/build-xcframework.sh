#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ "$#" -gt 0 ]; then
    SCHEMES=("$@")
else
    SCHEMES=(SrdzPermissions SrdzPermissionsTesting)
fi

SLICES=(
    "iphoneos|generic/platform=iOS|Release-iphoneos|arm64 arm64e"
    "iphonesimulator|generic/platform=iOS Simulator|Release-iphonesimulator|arm64 x86_64"
)

BUNDLE_ID_PREFIX="com.serjrodriguez"
MINIMUM_OS="15.0"
OUTPUT_DIR="$ROOT/build/xcframeworks"
WORK_DIR="$ROOT/build/work"

rm -rf "$OUTPUT_DIR" "$WORK_DIR"
mkdir -p "$OUTPUT_DIR" "$WORK_DIR"

write_info_plist() {
    local module="$1" destination="$2"
    cat > "$destination" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$module</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID_PREFIX.$module</string>
    <key>CFBundleName</key>
    <string>$module</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>$MINIMUM_OS</string>
</dict>
</plist>
EOF
}

MODULES=()

for slice in "${SLICES[@]}"; do
    IFS='|' read -r sdk destination configuration archs <<<"$slice"

    for scheme in "${SCHEMES[@]}"; do
        name="$scheme-$sdk"
        archive="$WORK_DIR/$name.xcarchive"
        derived="$WORK_DIR/$name-derived"

        echo "==> archiving $scheme for $sdk"
        xcodebuild archive \
            -scheme "$scheme" \
            -destination "$destination" \
            -archivePath "$archive" \
            -derivedDataPath "$derived" \
            ARCHS="$archs" \
            ONLY_ACTIVE_ARCH=NO \
            SKIP_INSTALL=NO \
            BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
            CODE_SIGNING_ALLOWED=NO \
            -quiet

        products_path="$derived/Build/Intermediates.noindex/ArchiveIntermediates/$scheme/BuildProductsPath/$configuration"

        while IFS= read -r object; do
            module="$(basename "$object" .o)"
            framework="$WORK_DIR/frameworks/$sdk/$module.framework"

            if [ -d "$framework" ]; then
                continue
            fi

            source="$products_path/$module.swiftmodule"
            if [ ! -d "$source" ]; then
                echo "error: missing module $module for $scheme ($sdk)" >&2
                exit 1
            fi

            mkdir -p "$framework/Modules/$module.swiftmodule"
            libtool -static -o "$framework/$module" "$object"
            find "$source" -name '*.swiftinterface' \
                ! -name '*.private.swiftinterface' \
                ! -name '*.package.swiftinterface' \
                -exec cp {} "$framework/Modules/$module.swiftmodule" \;
            find "$source" -name '*.swiftdoc' -exec cp {} "$framework/Modules/$module.swiftmodule" \;
            write_info_plist "$module" "$framework/Info.plist"

            case " ${MODULES[*]-} " in
                *" $module "*) ;;
                *) MODULES+=("$module") ;;
            esac
        done < <(find "$archive/Products" -name '*.o' | sort)
    done
done

for module in "${MODULES[@]}"; do
    echo "==> packaging $module"
    create_args=()
    for slice in "${SLICES[@]}"; do
        IFS='|' read -r sdk _ _ _ <<<"$slice"
        create_args+=(-framework "$WORK_DIR/frameworks/$sdk/$module.framework")
    done

    xcodebuild -create-xcframework "${create_args[@]}" -output "$OUTPUT_DIR/$module.xcframework"

    (cd "$OUTPUT_DIR" && ditto -c -k --norsrc --noextattr --keepParent "$module.xcframework" "$module.xcframework.zip")
    checksum="$(swift package compute-checksum "$OUTPUT_DIR/$module.xcframework.zip")"
    echo "$checksum" > "$OUTPUT_DIR/$module.xcframework.zip.checksum"
    echo "    checksum: $checksum"
done

rm -rf "$WORK_DIR"
echo "XCFrameworks written to $OUTPUT_DIR"
