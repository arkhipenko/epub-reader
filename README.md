# epub-reader

An ebook reader for Android and iOS, written in Flutter. It reads EPUB, FB2 and the other
text formats of its engine (see File formats).
The rendering engine is crengine, the engine that KOReader uses. Reading positions
are crengine XPointers, so they can be synchronized with KOReader through a kosync server.

## Layout

| Folder | Contents |
|---|---|
| `native/` | C interface to crengine (`src/cre_ffi.h`, `src/cre_ffi.cpp`) and the Android and iOS build scripts. `ios/` holds the patch that adds an iOS target to the KOReader build. |
| `app/` | The Flutter app. `lib/engine/` holds the FFI bindings and the engine isolate. |

## File formats

The table of formats is in `app/lib/library/book_formats.dart`. The library scan, the "open file"
entry, the OPDS downloads and the style sheet choice use it.

- Book formats: EPUB, FB2 (also zipped), FB3, MOBI, AZW, PRC, PDB (PalmDoc), TCR, CHM. The library
  scan always takes them.
- Text and office documents: TXT, RTF, DOC, DOCX, ODT, HTML, Markdown, and zipped TXT, RTF and
  HTML. A folder such as Download holds many of these that are not books. The library scan takes
  them only when "Also show text and office documents" is on (Library folders screen). A
  document that you open with "open file" or download from a catalog always shows.
- Not read: PDF, DjVu and comics (they need another engine), the newer Kindle format (azw3,
  KF8), files with copy protection, and zipped Markdown.

NOTE: A Kindle file that holds both the old and the new form opens with its old form.

## Line shift

A vertical drag on the page moves the text by whole lines, forward or back. On release a whole
line is at the top. A vertical drag in the left eighth of the screen still changes the brightness.

The page turns after a drag continue from the shifted line:

- Forward shows the text below the last line of the view. No line shows again and no line is
  skipped. Rows without text (margins) are skipped.
- Back shows the text above the first line of the view. Back after forward shows the same views.
- A view does not cross a forced page break (most books start each chapter on a new page). The
  view before a chapter start ends there, and the next turn shows the first page of the chapter.
  The reader is then on the fixed pages again.
- A link, the table of contents, the slider, a search hit or a position from the sync server goes
  to the fixed pages. The undo button and Android back after a link or a slider jump return to the
  shifted view that was on screen.
- A book that closes in a shifted view opens again as that view. A new layout (font, size, margins
  and the other reading settings) keeps the shifted view at its first line. The position is saved
  with a flag for this (`lastShifted` in the books table).

Highlights, the search mark and links operate in a shifted view. Text selection and in-page
footnotes do not.

The engine does not draw while the text moves. The reader places parts of the page images that
it already has (`app/lib/reader/widgets/shifted_page.dart`). The engine gives the rows of each
page with its forced page break, the rows of each text line, and the boxes of highlights and links
in these rows (`cre_doc_page_ranges`, `cre_doc_lines_in_range`, `cre_doc_range_rows` and
`cre_doc_links_in_rows` in `native/src/cre_ffi.h`). The rules are in `app/lib/reader/line_shift.dart`.

NOTE: The page splitter of the engine does not keep the reason for a page end. The engine finds a
forced page break from the page-break styles of the elements at the page start.

NOTE: These functions are in version 7 of the C interface. The app does not start with an engine
library of another version, so build the Android and the iOS library again after an update.

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
- The same test opens one sample file per format, when the files of `app/test/fixtures/formats/` are
  in the same folder as the sample books. `make_formats.py` in that folder makes the files again
  (it needs LibreOffice for RTF, DOC, DOCX and ODT). There is no CHM sample in the repository; put a
  CHM file there as `sample.chm` to check that format. A format without a sample is skipped.
- `integration_test/line_shift_test.dart` writes its own book (two long chapters and a footnote) and
  opens it in the reader screen. It drags the text three lines forward, turns the pages up to the
  next chapter and back again, and checks a highlight and a footnote link in a shifted view and the
  return from the footnote. It also checks a short drag, a drag of a whole page, a jump, a font size
  change in a shifted view, and a reopen in a shifted view and on a fixed page. It needs no sample
  files. `--dart-define=HOLD=5` keeps each state on screen for 5 seconds.
- `integration_test/opds_test.dart` uses the live Project Gutenberg catalog (network access and a new
  install are needed). It searches "The Picture of Dorian Gray", opens the page of book 174, checks the
  book sheet text, downloads the MOBI and the EPUB file, and opens the EPUB. It also reports whether
  the page from the server still has the markup error that the app corrects; when it no longer has
  it, `test/opds_repair_test.dart` with its saved pages is the proof of the correction.
- On Android, an integration test removes the app from the device when it ends. Before each run,
  install the debug APK and allow file access, or the test cannot read the Download folder:
  `adb shell appops set com.arkhipenko.epubreader MANAGE_EXTERNAL_STORAGE allow`
- In debug builds, the reader's Position info panel has a KOReader XPointer test for `juliet.epub`.
  It checks that the engine finds the same text as KOReader at five XPointers from the KOReader
  unit tests.

## License

Copyright (C) 2026 Anatoli Arkhipenko.

This program is free software under the GNU Affero General Public License, version 3 or
(at your option) any later version. The license text is in `LICENSE`.

The app includes parts from other projects: crengine (GPL), parts of KOReader (AGPL-3.0), fonts
and libraries. `NOTICE.md` lists them with their licenses and sources. The app shows the same
notices in About: the library menu, or a tap on the version line in the reading settings.

### Before you give the app to other persons

The GPL and AGPL apply when you give the app to other persons, for example through Google Play.
They do not apply to your own use.

1. Give the source code of the same version. Make this repository public, or give the source in a
   different way. Put a tag on the commit of each release build.
2. Keep the source available. koreader-base, crengine, koreader-fonts and the library sources are
   on servers that you do not control, and the GPL makes you responsible for them. Keep copies,
   for example a source archive with each release.
3. Give the license and the source code address in the store listing.

Google Play permits this. For the Apple App Store, the Free Software Foundation considers that the
App Store terms add restrictions that the GPL does not permit. A copyright holder of crengine or
KOReader can ask Apple to remove the app. TestFlight for your own use is not distribution to other
persons.
