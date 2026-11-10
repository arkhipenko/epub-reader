# epub-reader

An ebook reader for Android (iOS later), written in Flutter. It reads EPUB and FB2.
The rendering engine is crengine, the engine that KOReader uses. Reading positions
are crengine XPointers, so they can be synchronized with KOReader through a kosync server.

## Layout

| Folder | Contents |
|---|---|
| `native/` | C interface to crengine (`src/cre_ffi.h`, `src/cre_ffi.cpp`) and the Android build script. |
| `app/` | The Flutter app. `lib/engine/` holds the FFI bindings and the engine isolate. |

## Build

The native library builds on Linux (WSL is fine). The KOReader build scripts support Linux hosts only.

1. Install the tools: Android NDK r28c, cmake, ninja 1.13 or newer, meson, autoconf,
   automake, libtool, pkg-config, nasm, git, make.
2. Set `ANDROID_NDK_HOME` to the NDK folder.
3. Run `native/build-android.sh`. It does these steps:
   - It clones koreader-base and koreader-fonts at pinned commits.
   - It builds crengine and its libraries for each ABI (default: `arm64-v8a x86_64`).
   - It links `libcre_ffi.so` into `app/android/app/src/main/jniLibs/<abi>/`.
   - It copies fonts, CSS and hyphenation patterns into `app/assets/engine/`.
4. Build the app with Flutter from `app/`, for example `flutter build apk --debug`.

NOTE: The first build takes about 10 to 20 minutes. It downloads and compiles about 20 libraries.

NOTE: Steps 3 and 4 make files that are not in git. Run step 3 before the first Flutter build.

## Tests

- `flutter test` in `app/` checks the KOReader document fingerprint (partial MD5) against
  the values in the KOReader unit tests.
- Sample books are not in the app. For manual tests, copy them to the device, where the library
  finds them in the Download folder:
  `adb push app/test/fixtures/leaves.epub app/test/fixtures/juliet.epub app/test/fixtures/sample.fb2 /sdcard/Download/`
- In debug builds, the reader's Position info panel has a KOReader XPointer test for `juliet.epub`.
  It checks that the engine finds the same text as KOReader at five XPointers from the KOReader
  unit tests.

## License

For personal use. crengine and the KOReader sources are under the GPL and AGPL licenses.
