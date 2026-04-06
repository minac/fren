#!/bin/bash
set -e

cd "$(dirname "$0")"

APP_NAME="Fren"
PROJECT="Fren.xcodeproj"
SCHEME="Fren"
BUILD_DIR="build"
ENTITLEMENTS="Fren/Fren.entitlements"

# Default signing identity (override with CODESIGN_IDENTITY env var)
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-Developer ID Application: Miguel Pereira Torcato David (F6RMP8HFLW)}"
NOTARY_PROFILE="${NOTARY_PROFILE:-notarytool-profile}"

usage() {
    cat <<EOF
Usage: $0 [command] [options]

Commands:
  build [debug|release]  Build via xcodebuild
  test                   Run all tests
  run                    Build debug and launch
  package                Build release .app to build/
  sign                   Code sign the release .app
  dmg <version>          Create signed + notarized DMG
  release <version>      Full pipeline: build → sign → dmg → notarize

Environment variables:
  FREN_LANGUAGES          Comma-separated language codes (default: EN,FR)
  CODESIGN_IDENTITY       Developer ID signing identity
  NOTARY_PROFILE          Notarytool keychain profile name
EOF
}

derived_data_app() {
    local config="${1:-Debug}"
    xcodebuild -project "$PROJECT" -scheme "$SCHEME" -configuration "$config" \
        -showBuildSettings 2>/dev/null | grep ' BUILT_PRODUCTS_DIR' | awk '{print $3}'
}

cmd_build() {
    local config="${1:-debug}"
    local xc_config

    case "$config" in
        debug)   xc_config="Debug" ;;
        release) xc_config="Release" ;;
        *)
            echo "Usage: $0 build [debug|release]"
            exit 1
            ;;
    esac

    echo "Building $config..."
    xcodebuild build \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination 'platform=macOS' \
        -configuration "$xc_config" \
        2>&1 | tail -3
}

cmd_test() {
    echo "Running tests..."
    xcodebuild test \
        -project "$PROJECT" \
        -scheme "$SCHEME" \
        -destination 'platform=macOS' \
        2>&1 | grep -E '(Test Suite|Executed|FAILED|error:)' | tail -10
}

cmd_run() {
    cmd_build debug
    local app_dir
    app_dir="$(derived_data_app Debug)/$APP_NAME.app"
    echo "Launching $app_dir..."
    open "$app_dir"
}

cmd_package() {
    cmd_build release
    local src_app
    src_app="$(derived_data_app Release)/$APP_NAME.app"
    mkdir -p "$BUILD_DIR/release"
    rm -rf "$BUILD_DIR/release/$APP_NAME.app"
    cp -R "$src_app" "$BUILD_DIR/release/$APP_NAME.app"
    echo "Packaged: $BUILD_DIR/release/$APP_NAME.app"
}

cmd_sign() {
    local app_dir="$BUILD_DIR/release/$APP_NAME.app"

    if [ ! -d "$app_dir" ]; then
        echo "Error: $app_dir not found. Run '$0 package' first."
        exit 1
    fi

    echo "Signing $app_dir..."
    codesign --force --options runtime \
        --entitlements "$ENTITLEMENTS" \
        --sign "$CODESIGN_IDENTITY" \
        "$app_dir"

    echo "Verifying signature..."
    codesign --verify --deep --strict "$app_dir"
    echo "Signature valid."
}

cmd_dmg() {
    local version="$1"
    if [ -z "$version" ]; then
        echo "Usage: $0 dmg <version>"
        exit 1
    fi

    local app_dir="$BUILD_DIR/release/$APP_NAME.app"
    local dmg="$BUILD_DIR/release/$APP_NAME-$version.dmg"

    if [ ! -d "$app_dir" ]; then
        echo "Error: $app_dir not found. Run '$0 package' first."
        exit 1
    fi

    echo "Creating DMG..."
    rm -f "$dmg"

    if command -v create-dmg &>/dev/null; then
        create-dmg \
            --volname "$APP_NAME" \
            --window-size 600 400 \
            --icon "$APP_NAME.app" 150 200 \
            --app-drop-link 450 200 \
            "$dmg" \
            "$app_dir"
    else
        hdiutil create -volname "$APP_NAME" \
            -srcfolder "$app_dir" \
            -ov -format UDZO \
            "$dmg"
    fi

    echo "Signing DMG..."
    codesign --force --sign "$CODESIGN_IDENTITY" "$dmg"

    echo "Notarizing..."
    xcrun notarytool submit "$dmg" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait --timeout 30m

    echo "Stapling..."
    xcrun stapler staple "$dmg"

    echo "DMG ready: $dmg"
}

cmd_release() {
    local version="$1"
    if [ -z "$version" ]; then
        echo "Usage: $0 release <version>"
        exit 1
    fi

    cmd_package
    cmd_sign
    cmd_dmg "$version"

    echo ""
    echo "Release $version complete!"
    echo "  DMG: $BUILD_DIR/release/$APP_NAME-$version.dmg"
}

case "${1:-}" in
    build)
        cmd_build "${2:-debug}"
        ;;
    test)
        cmd_test
        ;;
    run)
        cmd_run
        ;;
    package)
        cmd_package
        ;;
    sign)
        cmd_sign
        ;;
    dmg)
        cmd_dmg "$2"
        ;;
    release)
        cmd_release "$2"
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        echo "Unknown command: ${1:-}"
        usage
        exit 1
        ;;
esac
