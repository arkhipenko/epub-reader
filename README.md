# epub-reader

An ebook reader for Android and iOS, written in Flutter. It reads EPUB and FB2.
The rendering engine is crengine, the engine that KOReader uses. Reading positions
are crengine XPointers, so they can be synchronized with KOReader through a kosync server.

## Layout

| Folder | Contents |
|---|---|
| `native/` | C interface to crengine (`src/cre_ffi.h`, `src/cre_ffi.cpp`) and the Android and iOS build scripts. `ios/` holds the patch that adds an iOS target to the KOReader build. |
| `app/` | The Flutter app. `lib/engine/` holds the FFI bindings and the engine isolate. |

## Build

### Android

The native library builds on Linux (WSL is fine). The KOReader build scripts support Linux hosts only
for Android.

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

### iOS

The native library builds on macOS with Xcode. KOReader has no iOS target. The script applies
`native/ios/koreader-base-ios.patch` to its koreader-base checkout to add one.

1. Install Xcode and the tools from Homebrew:
   `brew install cmake ninja meson make autoconf automake libtool pkg-config wget coreutils findutils util-linux`
2. Run `native/build-ios.sh`. It does these steps:
   - It clones koreader-base and koreader-fonts at the same pinned commits as the Android script.
   - It builds crengine and its libraries for each SDK (default: `iphonesimulator iphoneos`).
     To build for the simulator only, set `SDKS=iphonesimulator`.
   - It merges `cre_ffi` and the libraries into one object, in which only the `cre_*` functions
     are global, and writes it to `app/ios/CreEngine/<sdk>/libcre_ffi.a`.
   - It copies fonts, CSS and hyphenation patterns into `app/assets/engine/`.
3. Build the app with Flutter from `app/`, for example `flutter build ios --simulator --debug`.

The app links the engine statically (`app/ios/Flutter/CreEngine.xcconfig`). Dart finds the
functions with `DynamicLibrary.process()`. The simulator build is for Apple silicon Macs only (arm64).

NOTE: The Xcode build stops with "file not found" for `libcre_ffi.a` until step 2 is complete.

## Tests

- `flutter test` in `app/` checks the KOReader document fingerprint (partial MD5) against
  the values in the KOReader unit tests.
- Sample books are not in the app. For manual tests, copy them to the device, where the library
  finds them in the Download folder:
  `adb push app/test/fixtures/leaves.epub app/test/fixtures/juliet.epub app/test/fixtures/sample.fb2 /sdcard/Download/`
- `integration_test/engine_test.dart` runs the engine on a device or simulator. It opens the sample
  books, draws a page of each, and checks the KOReader XPointers in `juliet.epub`. With `sample.fb2` it
  also checks that the book language and each advanced setting change the page. The sample books
  are not in the app, so give their folder. On the iOS simulator, which can read the Mac file system:
  `flutter test integration_test/engine_test.dart -d <simulator> --dart-define=FIXTURES=$PWD/test/fixtures`
- In debug builds, the reader's Position info panel has a KOReader XPointer test for `juliet.epub`.
  It checks that the engine finds the same text as KOReader at five XPointers from the KOReader
  unit tests.

## License

For personal use. crengine and the KOReader sources are under the GPL and AGPL licenses.
