#!/usr/bin/env bash
#
# Build libcre_ffi.a (crengine + the cre_ffi C wrapper) for iOS, and stage
# the engine data (fonts, CSS, hyphenation patterns) for the Flutter app.
#
# Host: macOS with Xcode. KOReader has no iOS target. The patch
# native/ios/koreader-base-ios.patch adds one to the KOReader build system.
#
# Required tools: Xcode, git, and from Homebrew:
#   brew install cmake ninja meson make autoconf automake libtool pkg-config \
#                wget coreutils findutils util-linux
#
# Usage:
#   native/build-ios.sh                          # simulator and device
#   SDKS=iphonesimulator native/build-ios.sh     # simulator only
#
# Environment:
#   SDKS               SDKs to build (default: "iphonesimulator iphoneos")
#   IOS_MIN            minimum iOS version (default: 15.0, as in the Xcode project)
#   CRE_WORK_DIR       work folder (default: ~/build/epub-reader-native)
#   KOREADER_BASE_DIR  use an existing koreader-base checkout instead of cloning
#                      (the script applies the iOS patch to it)
#
# Output (not in git):
#   app/ios/CreEngine/<sdk>/libcre_ffi.a   one object; only the cre_* symbols are global
#   app/assets/engine/                     fonts, CSS and hyphenation patterns
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
NATIVE_DIR="$REPO_DIR/native"
APP_DIR="$REPO_DIR/app"

WORK_DIR="${CRE_WORK_DIR:-$HOME/build/epub-reader-native}"
SDKS="${SDKS:-iphonesimulator iphoneos}"
IOS_MIN="${IOS_MIN:-15.0}"

# Pinned sources. Keep these in step with build-android.sh.
KOREADER_BASE_URL="https://github.com/koreader/koreader-base.git"
KOREADER_BASE_COMMIT="b153a4a252f6e4295af7a569bcfdd59ffa688fa6"
KOREADER_FONTS_URL="https://github.com/koreader/koreader-fonts.git"
KOREADER_FONTS_COMMIT="046976988aa33639d60d6ffd25c7a0ff50b72ac0"

IOS_PATCH="$NATIVE_DIR/ios/koreader-base-ios.patch"
# Compiler prefix of the KOReader iOS target (see the patch). Autotools know it.
CHOST="aarch64-apple-darwin"

export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.autocrlf GIT_CONFIG_VALUE_0=false

log() { printf '\n=== %s\n' "$*"; }

# The KOReader build helpers need GNU find and xargs, flock, tac, gln and
# libtoolize. KOReader's macOS CI puts the same Homebrew folders in PATH.
setup_host_path() {
    local brew
    brew="$(brew --prefix)"
    HOST_BIN="$WORK_DIR/host-bin"
    mkdir -p "$HOST_BIN"
    if command -v gtac >/dev/null; then
        ln -sf "$(command -v gtac)" "$HOST_BIN/tac"
    fi
    export PATH="$HOST_BIN:$brew/opt/findutils/libexec/gnubin:$brew/opt/util-linux/bin:$brew/opt/libtool/libexec/gnubin:$brew/opt/make/libexec/gnubin:$PATH"
}

check_tools() {
    local missing=() t
    for t in xcrun git make cmake ninja meson autoconf automake libtoolize pkg-config wget gln tac flock; do
        command -v "$t" >/dev/null || missing+=("$t")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing tools: ${missing[*]}" >&2
        echo "Install: brew install cmake ninja meson make autoconf automake libtool pkg-config wget coreutils findutils util-linux" >&2
        exit 1
    fi
    find --version 2>/dev/null | grep -q GNU || { echo "GNU find not first in PATH (brew install findutils)" >&2; exit 1; }
    case "$(make --version | head -1)" in
        "GNU Make 4."[1-9]*|"GNU Make "[5-9]*) ;;
        *) echo "GNU make 4.1 or newer is required (brew install make)" >&2; exit 1 ;;
    esac
    local nv
    nv="$(ninja --version)"
    case "$nv" in
        1.1[3-9]*|1.[2-9][0-9]*|[2-9].*) ;;
        *) echo "ninja $nv found. KOReader requires ninja 1.13 or newer." >&2; exit 1 ;;
    esac
}

fetch_koreader_base() {
    if [ -n "${KOREADER_BASE_DIR:-}" ]; then
        KOBASE="$KOREADER_BASE_DIR"
    else
        KOBASE="$WORK_DIR/koreader/base"
        if [ ! -d "$KOBASE/.git" ]; then
            log "Cloning koreader-base"
            git clone --no-checkout "$KOREADER_BASE_URL" "$KOBASE"
        fi
        git -C "$KOBASE" checkout -q "$KOREADER_BASE_COMMIT"
        git -C "$KOBASE" submodule update --init thirdparty/kpvcrlib/crengine
    fi
    if ! git -C "$KOBASE" apply --reverse --check "$IOS_PATCH" 2>/dev/null; then
        log "Adding the iOS target to koreader-base"
        git -C "$KOBASE" apply "$IOS_PATCH"
    fi
}

fetch_fonts() {
    FONTS_DIR="$WORK_DIR/koreader-fonts"
    if [ ! -d "$FONTS_DIR/.git" ]; then
        log "Cloning koreader-fonts"
        git clone --no-checkout "$KOREADER_FONTS_URL" "$FONTS_DIR"
    fi
    git -C "$FONTS_DIR" checkout -q "$KOREADER_FONTS_COMMIT"
}

# SDK -> KOReader target, clang target triple and ld platform name.
sdk_target() {
    case "$1" in
        iphonesimulator) echo "ios-simulator" ;;
        iphoneos)        echo "ios" ;;
        *) echo "unsupported SDK $1" >&2; exit 1 ;;
    esac
}
sdk_triple() {
    case "$1" in
        iphonesimulator) echo "arm64-apple-ios${IOS_MIN}-simulator" ;;
        iphoneos)        echo "arm64-apple-ios${IOS_MIN}" ;;
    esac
}
sdk_platform() {
    case "$1" in
        iphonesimulator) echo "ios-simulator" ;;
        iphoneos)        echo "ios" ;;
    esac
}

# Compiler and binutils wrappers with the KOReader CHOST prefix. They fix
# the SDK and the target triple for every call that the build makes.
make_wrappers() {
    local sdk="$1" sysroot triple t
    WRAP_DIR="$WORK_DIR/ios-toolchain/$sdk"
    sysroot="$(xcrun --sdk "$sdk" --show-sdk-path)"
    triple="$(sdk_triple "$sdk")"
    mkdir -p "$WRAP_DIR"
    for t in clang clang++; do
        printf '#!/bin/sh\nexec "%s" -target %s -isysroot "%s" "$@"\n' \
            "$(xcrun --sdk "$sdk" -f "$t")" "$triple" "$sysroot" > "$WRAP_DIR/$CHOST-$t"
    done
    for t in ar ld nm ranlib strip; do
        printf '#!/bin/sh\nexec "%s" "$@"\n' "$(xcrun --sdk "$sdk" -f "$t")" > "$WRAP_DIR/$CHOST-$t"
    done
    chmod +x "$WRAP_DIR"/*
    SDK_PATH="$sysroot"
}

build_crengine() {
    local sdk="$1" target logf
    target="$(sdk_target "$sdk")"
    logf="$WORK_DIR/crengine-$sdk.log"
    log "Building crengine for $sdk (log: $logf)"
    : > "$logf"
    if ! PATH="$WRAP_DIR:$PATH" IOS_SDK_PATH="$SDK_PATH" \
        make -C "$KOBASE" TARGET="$target" KODEBUG= crengine >>"$logf" 2>&1; then
        tail -40 "$logf" >&2
        echo "crengine build failed for $sdk. See $logf" >&2
        exit 1
    fi
}

# Compile cre_ffi.cpp and merge it with crengine and its libraries into one
# object. Only the cre_* symbols stay global, so the libraries inside cannot
# clash with other copies in the app (zlib, libpng and so on).
build_wrapper() {
    local sdk="$1" machine machine_dir out sdkver
    machine="$("$WRAP_DIR/$CHOST-clang" -dumpmachine)"
    machine_dir="$KOBASE/build/$machine"
    [ -d "$machine_dir" ] || { echo "No KOReader build folder for $sdk ($machine_dir)" >&2; exit 1; }
    local staging="$machine_dir/staging/lib"
    local inc="$machine_dir/staging/include"
    local crebuild="$machine_dir/thirdparty/crengine/build"
    out="$NATIVE_DIR/out/$sdk"
    mkdir -p "$out"
    log "Linking libcre_ffi.a for $sdk"
    "$WRAP_DIR/$CHOST-clang++" -std=c++17 -O2 -fPIC \
        -fvisibility=hidden -fvisibility-inlines-hidden \
        -DNDEBUG -DCR3_ANTIWORD_PATCH=1 \
        -I"$crebuild" \
        -I"$KOBASE/thirdparty/kpvcrlib/crengine/crengine/include" \
        -isystem "$inc/freetype2" -isystem "$inc" -isystem "$inc/fribidi" \
        -isystem "$inc/harfbuzz" -isystem "$inc/libpng16" -isystem "$inc/webp" \
        -c "$NATIVE_DIR/src/cre_ffi.cpp" -o "$out/cre_ffi.o"
    echo '_cre_*' > "$out/exports.txt"
    sdkver="$(xcrun --sdk "$sdk" --show-sdk-version)"
    xcrun --sdk "$sdk" ld -r -arch arm64 \
        -platform_version "$(sdk_platform "$sdk")" "$IOS_MIN" "$sdkver" \
        -exported_symbols_list "$out/exports.txt" \
        -o "$out/cre_ffi_all.o" \
        "$out/cre_ffi.o" \
        "$crebuild/libcrengine.a" \
        "$staging/libfreetype.a" "$staging/libharfbuzz.a" "$staging/libfribidi.a" \
        "$staging/libunibreak.a" "$staging/libjpeg.a" "$staging/libpng16.a" \
        "$staging/libwebpdemux.a" "$staging/libwebp.a" "$staging/libsharpyuv.a" \
        "$staging/liblunasvg.a" "$staging/libmd4c-html.a" "$staging/libmd4c.a" \
        "$staging/libutf8proc.a" "$staging/libxxhash.a" "$staging/libzstd.a" \
        "$staging/libbrotlidec.a" "$staging/libbrotlicommon.a" "$staging/libz.a"
    # Link check: every symbol that is still undefined must come from the
    # iOS system libraries (libSystem and libc++).
    printf 'int cre_ffi_version(void);\nint main(void) { return cre_ffi_version(); }\n' > "$out/linktest.c"
    "$WRAP_DIR/$CHOST-clang++" -x c "$out/linktest.c" -x none "$out/cre_ffi_all.o" -o "$out/linktest"
    rm -f "$out/libcre_ffi.a"
    xcrun --sdk "$sdk" libtool -static -o "$out/libcre_ffi.a" "$out/cre_ffi_all.o"
    mkdir -p "$APP_DIR/ios/CreEngine/$sdk"
    cp "$out/libcre_ffi.a" "$APP_DIR/ios/CreEngine/$sdk/"
    ls -la "$APP_DIR/ios/CreEngine/$sdk/libcre_ffi.a"
}

stage_engine_data() {
    local data="$KOBASE/thirdparty/kpvcrlib/crengine/cr3gui/data"
    local dst="$APP_DIR/assets/engine"
    log "Staging engine data into $dst"
    rm -rf "$dst"
    mkdir -p "$dst/css" "$dst/hyph" "$dst/fonts"
    cp "$data"/*.css "$dst/css/"
    cp "$data"/hyph/* "$dst/hyph/"
    # Same font set as build-android.sh.
    find "$FONTS_DIR/noto" -name '*.ttf' -exec cp {} "$dst/fonts/" \;
    cp "$FONTS_DIR/droid/DroidSansMono.ttf" "$dst/fonts/"
    cp "$FONTS_DIR"/freefont/*.ttf "$dst/fonts/"
}

main() {
    mkdir -p "$WORK_DIR"
    setup_host_path
    check_tools
    fetch_koreader_base
    fetch_fonts
    local sdk
    for sdk in $SDKS; do
        make_wrappers "$sdk"
        build_crengine "$sdk"
        build_wrapper "$sdk"
    done
    stage_engine_data
    log "Done"
}

main "$@"
