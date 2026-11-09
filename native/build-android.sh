#!/usr/bin/env bash
#
# Build libcre_ffi.so (crengine + the cre_ffi C wrapper) for Android, and
# stage the engine data (fonts, CSS, hyphenation patterns) for the Flutter app.
#
# Host: Linux (WSL on Windows is fine). KOReader build scripts support Linux only.
#
# Required tools: Android NDK (ANDROID_NDK_HOME), cmake, ninja 1.13 or newer,
# meson, autoconf, automake, libtool, pkg-config, nasm, git, make.
#
# Usage:
#   native/build-android.sh                 # all ABIs in $ABIS
#   ABIS="arm64-v8a" native/build-android.sh
#
# Environment:
#   ANDROID_NDK_HOME   NDK root (required)
#   ABIS               ABIs to build (default: "arm64-v8a x86_64")
#   CRE_WORK_DIR       work folder on a Linux file system (default: ~/build/epub-reader-native)
#   KOREADER_BASE_DIR  use an existing koreader-base checkout (LF line endings) instead of cloning
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
NATIVE_DIR="$REPO_DIR/native"
APP_DIR="$REPO_DIR/app"

WORK_DIR="${CRE_WORK_DIR:-$HOME/build/epub-reader-native}"
ABIS="${ABIS:-arm64-v8a x86_64}"
API_LEVEL=26

# Pinned sources. These are the commits that the KOReader checkout used for
# the design work refers to (koreader a3ebf281f, 2026-11-08).
KOREADER_BASE_URL="https://github.com/koreader/koreader-base.git"
KOREADER_BASE_COMMIT="b153a4a252f6e4295af7a569bcfdd59ffa688fa6"
KOREADER_FONTS_URL="https://github.com/koreader/koreader-fonts.git"
KOREADER_FONTS_COMMIT="046976988aa33639d60d6ffd25c7a0ff50b72ac0"

: "${ANDROID_NDK_HOME:?Set ANDROID_NDK_HOME to the Android NDK root}"
TOOLCHAIN="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64"

# A global core.autocrlf=true converts the sources that the build downloads
# to CRLF, and the KOReader patches then fail. Override it for this script only.
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.autocrlf GIT_CONFIG_VALUE_0=false

log() { printf '\n=== %s\n' "$*"; }

check_tools() {
    local missing=()
    for t in cmake ninja meson autoconf automake libtoolize pkg-config nasm git make; do
        command -v "$t" >/dev/null || missing+=("$t")
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing tools: ${missing[*]}" >&2
        exit 1
    fi
    local nv
    nv="$(ninja --version)"
    case "$nv" in
        1.1[3-9]*|1.[2-9][0-9]*|[2-9].*) ;;
        *) echo "ninja $nv found. KOReader requires ninja 1.13 or newer (for example: pip install ninja)." >&2; exit 1 ;;
    esac
}

fetch_koreader_base() {
    if [ -n "${KOREADER_BASE_DIR:-}" ]; then
        KOBASE="$KOREADER_BASE_DIR"
        return
    fi
    KOBASE="$WORK_DIR/koreader/base"
    if [ ! -d "$KOBASE/.git" ]; then
        log "Cloning koreader-base"
        git clone --no-checkout "$KOREADER_BASE_URL" "$KOBASE"
    fi
    git -C "$KOBASE" checkout -q "$KOREADER_BASE_COMMIT"
    git -C "$KOBASE" submodule update --init thirdparty/kpvcrlib/crengine
    # The base build refers to this folder. Only the 7z target uses it.
    mkdir -p "$WORK_DIR/koreader/platform/android/luajit-launcher"
}

fetch_fonts() {
    FONTS_DIR="$WORK_DIR/koreader-fonts"
    if [ ! -d "$FONTS_DIR/.git" ]; then
        log "Cloning koreader-fonts"
        git clone --no-checkout "$KOREADER_FONTS_URL" "$FONTS_DIR"
    fi
    git -C "$FONTS_DIR" checkout -q "$KOREADER_FONTS_COMMIT"
}

# ABI -> KOReader target, compiler triple prefix, and KOReader output folder name.
abi_target() {
    case "$1" in
        arm64-v8a)   echo "android-arm64" ;;
        armeabi-v7a) echo "android-arm" ;;
        x86_64)      echo "android-x86_64" ;;
        *) echo "unsupported ABI $1" >&2; exit 1 ;;
    esac
}
abi_triple() {
    case "$1" in
        arm64-v8a)   echo "aarch64-linux-android" ;;
        armeabi-v7a) echo "armv7a-linux-androideabi" ;;
        x86_64)      echo "x86_64-linux-android" ;;
    esac
}

build_crengine() {
    local abi="$1" target logf
    target="$(abi_target "$abi")"
    logf="$WORK_DIR/crengine-$abi.log"
    log "Building crengine for $abi (log: $logf)"
    : > "$logf"
    # GNU make before 4.4 cannot pass its job server through ninja, and
    # autotools projects then fail with "read jobs pipe: Bad file descriptor".
    # Build such a project serially and continue in parallel.
    make -C "$KOBASE" -j1 TARGET="$target" KODEBUG= libunibreak >>"$logf" 2>&1
    local i failed
    for i in 1 2 3 4 5 6; do
        if make -C "$KOBASE" TARGET="$target" KODEBUG= crengine >>"$logf" 2>&1; then
            return 0
        fi
        failed="$(grep -oE 'FAILED: .*thirdparty/[a-z0-9_-]+/stamp' "$logf" | tail -1 | sed -E 's#.*/thirdparty/([^/]+)/stamp#\1#')"
        [ -n "$failed" ] || break
        echo "retry serial: $failed" | tee -a "$logf"
        make -C "$KOBASE" -j1 TARGET="$target" KODEBUG= "$failed" >>"$logf" 2>&1 || break
    done
    echo "crengine build failed for $abi. See $logf" >&2
    exit 1
}

build_wrapper() {
    local abi="$1" triple machine_dir out cxx
    triple="$(abi_triple "$abi")"
    machine_dir="$(ls -d "$KOBASE"/build/*/ | grep -E "/${triple%%-*}[^/]*android" | head -1)"
    machine_dir="${machine_dir%/}"
    [ -d "$machine_dir" ] || { echo "No KOReader build folder for $abi" >&2; exit 1; }
    local staging="$machine_dir/staging/lib"
    local inc="$machine_dir/staging/include"
    local crebuild="$machine_dir/thirdparty/crengine/build"
    out="$NATIVE_DIR/out/$abi"
    mkdir -p "$out"
    cxx="$TOOLCHAIN/bin/clang++"
    log "Linking libcre_ffi.so for $abi"
    "$cxx" --target="${triple}${API_LEVEL}" -std=c++17 -O2 -fPIC \
        -fvisibility=hidden -fvisibility-inlines-hidden \
        -ffunction-sections -fdata-sections \
        -DNDEBUG -DCR3_ANTIWORD_PATCH=1 \
        -I"$crebuild" \
        -I"$KOBASE/thirdparty/kpvcrlib/crengine/crengine/include" \
        -isystem "$inc/freetype2" -isystem "$inc" -isystem "$inc/fribidi" \
        -isystem "$inc/harfbuzz" -isystem "$inc/libpng16" -isystem "$inc/webp" \
        -c "$NATIVE_DIR/src/cre_ffi.cpp" -o "$out/cre_ffi.o"
    "$cxx" --target="${triple}${API_LEVEL}" -shared -o "$out/libcre_ffi.so" \
        -Wl,-soname,libcre_ffi.so \
        -Wl,--gc-sections -Wl,--no-undefined -Wl,--exclude-libs,ALL \
        -Wl,-z,max-page-size=16384 \
        -static-libstdc++ \
        "$out/cre_ffi.o" \
        -Wl,--start-group \
        "$crebuild/libcrengine.a" \
        "$staging/libfreetype.a" "$staging/libharfbuzz.a" "$staging/libfribidi.a" \
        "$staging/libunibreak.a" "$staging/libjpeg.a" "$staging/libpng16.a" \
        "$staging/libwebpdemux.a" "$staging/libwebp.a" "$staging/libsharpyuv.a" \
        "$staging/liblunasvg.a" "$staging/libmd4c-html.a" "$staging/libmd4c.a" \
        "$staging/libutf8proc.a" "$staging/libxxhash.a" "$staging/libzstd.a" \
        "$staging/libbrotlidec.a" "$staging/libbrotlicommon.a" "$staging/libz.a" \
        -Wl,--end-group \
        -llog -lm -ldl
    "$TOOLCHAIN/bin/llvm-strip" --strip-unneeded "$out/libcre_ffi.so"
    mkdir -p "$APP_DIR/android/app/src/main/jniLibs/$abi"
    cp "$out/libcre_ffi.so" "$APP_DIR/android/app/src/main/jniLibs/$abi/"
    ls -la "$out/libcre_ffi.so"
}

stage_engine_data() {
    local data="$KOBASE/thirdparty/kpvcrlib/crengine/cr3gui/data"
    local dst="$APP_DIR/assets/engine"
    log "Staging engine data into $dst"
    rm -rf "$dst"
    mkdir -p "$dst/css" "$dst/hyph" "$dst/fonts"
    cp "$data"/*.css "$dst/css/"
    cp "$data"/hyph/* "$dst/hyph/"
    # KOReader registers every font except the URW set and the Nerd Fonts symbols.
    # The CJK fallback (about 16 MB) is left out for now.
    find "$FONTS_DIR/noto" -name '*.ttf' -exec cp {} "$dst/fonts/" \;
    cp "$FONTS_DIR/droid/DroidSansMono.ttf" "$dst/fonts/"
    cp "$FONTS_DIR"/freefont/*.ttf "$dst/fonts/"
}

main() {
    check_tools
    mkdir -p "$WORK_DIR"
    fetch_koreader_base
    fetch_fonts
    for abi in $ABIS; do
        build_crengine "$abi"
        build_wrapper "$abi"
    done
    stage_engine_data
    log "Done"
}

main "$@"
