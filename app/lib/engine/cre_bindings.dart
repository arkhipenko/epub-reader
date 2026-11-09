// dart:ffi bindings for libcre_ffi (native/src/cre_ffi.h).
//
// Every function here blocks. Call them only from the engine isolate.
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Opaque native document handle.
final class CreDoc extends Opaque {}

/// The C interface version this file is written for (CRE_FFI_VERSION).
const int kCreFfiVersion = 2;

/// cre_doc_draw_page() flag: invert images (for the dark theme, which
/// inverts the whole page afterwards).
const int kDrawInvertImages = 1;

class CreBindings {
  CreBindings(DynamicLibrary lib)
      : ffiVersion = lib.lookupFunction<Int32 Function(), int Function()>('cre_ffi_version'),
        _init = lib.lookupFunction<Int32 Function(Pointer<Utf8>, Int32, Pointer<Utf8>),
            int Function(Pointer<Utf8>, int, Pointer<Utf8>)>('cre_init'),
        _registerFont = lib.lookupFunction<Int32 Function(Pointer<Utf8>), int Function(Pointer<Utf8>)>(
            'cre_register_font'),
        _fontsDone = lib.lookupFunction<Void Function(Pointer<Utf8>), void Function(Pointer<Utf8>)>(
            'cre_fonts_done'),
        latestDomVersion = lib.lookupFunction<Int32 Function(), int Function()>('cre_latest_dom_version'),
        docNew = lib.lookupFunction<Pointer<CreDoc> Function(Int32, Int32), Pointer<CreDoc> Function(int, int)>(
            'cre_doc_new'),
        docFree = lib.lookupFunction<Void Function(Pointer<CreDoc>), void Function(Pointer<CreDoc>)>('cre_doc_free'),
        docApplyDefaults = lib.lookupFunction<Void Function(Pointer<CreDoc>, Int32), void Function(Pointer<CreDoc>, int)>(
            'cre_doc_apply_defaults'),
        _docSetInt = lib.lookupFunction<Void Function(Pointer<CreDoc>, Pointer<Utf8>, Int32),
            void Function(Pointer<CreDoc>, Pointer<Utf8>, int)>('cre_doc_set_int'),
        _docSetString = lib.lookupFunction<Void Function(Pointer<CreDoc>, Pointer<Utf8>, Pointer<Utf8>),
            void Function(Pointer<CreDoc>, Pointer<Utf8>, Pointer<Utf8>)>('cre_doc_set_string'),
        _docSetStylesheet = lib.lookupFunction<Void Function(Pointer<CreDoc>, Pointer<Utf8>, Pointer<Utf8>),
            void Function(Pointer<CreDoc>, Pointer<Utf8>, Pointer<Utf8>)>('cre_doc_set_stylesheet'),
        _docSetFontFace = lib.lookupFunction<Void Function(Pointer<CreDoc>, Pointer<Utf8>),
            void Function(Pointer<CreDoc>, Pointer<Utf8>)>('cre_doc_set_font_face'),
        docSetFontSize = lib.lookupFunction<Void Function(Pointer<CreDoc>, Int32), void Function(Pointer<CreDoc>, int)>(
            'cre_doc_set_font_size'),
        docSetInterline = lib.lookupFunction<Void Function(Pointer<CreDoc>, Int32), void Function(Pointer<CreDoc>, int)>(
            'cre_doc_set_interline'),
        docSetMargins = lib.lookupFunction<Void Function(Pointer<CreDoc>, Int32, Int32, Int32, Int32),
            void Function(Pointer<CreDoc>, int, int, int, int)>('cre_doc_set_margins'),
        docSetColors = lib.lookupFunction<Void Function(Pointer<CreDoc>, Uint32, Uint32),
            void Function(Pointer<CreDoc>, int, int)>('cre_doc_set_colors'),
        _docLoad = lib.lookupFunction<Int32 Function(Pointer<CreDoc>, Pointer<Utf8>),
            int Function(Pointer<CreDoc>, Pointer<Utf8>)>('cre_doc_load'),
        docResize = lib.lookupFunction<Void Function(Pointer<CreDoc>, Int32, Int32),
            void Function(Pointer<CreDoc>, int, int)>('cre_doc_resize'),
        docRender = lib.lookupFunction<Void Function(Pointer<CreDoc>), void Function(Pointer<CreDoc>)>(
            'cre_doc_render'),
        docPageCount = lib.lookupFunction<Int32 Function(Pointer<CreDoc>), int Function(Pointer<CreDoc>)>(
            'cre_doc_page_count'),
        docCurrentPage = lib.lookupFunction<Int32 Function(Pointer<CreDoc>), int Function(Pointer<CreDoc>)>(
            'cre_doc_current_page'),
        docGotoPage = lib.lookupFunction<Void Function(Pointer<CreDoc>, Int32), void Function(Pointer<CreDoc>, int)>(
            'cre_doc_goto_page'),
        _docGotoXPointer = lib.lookupFunction<Int32 Function(Pointer<CreDoc>, Pointer<Utf8>),
            int Function(Pointer<CreDoc>, Pointer<Utf8>)>('cre_doc_goto_xpointer'),
        _docGetXPointer = lib.lookupFunction<Pointer<Utf8> Function(Pointer<CreDoc>),
            Pointer<Utf8> Function(Pointer<CreDoc>)>('cre_doc_get_xpointer'),
        _docPageOfXPointer = lib.lookupFunction<Int32 Function(Pointer<CreDoc>, Pointer<Utf8>),
            int Function(Pointer<CreDoc>, Pointer<Utf8>)>('cre_doc_page_of_xpointer'),
        docPercent = lib.lookupFunction<Int32 Function(Pointer<CreDoc>), int Function(Pointer<CreDoc>)>(
            'cre_doc_percent'),
        _docTextAtXPointer = lib.lookupFunction<Pointer<Utf8> Function(Pointer<CreDoc>, Pointer<Utf8>, Int32),
            Pointer<Utf8> Function(Pointer<CreDoc>, Pointer<Utf8>, int)>('cre_doc_text_at_xpointer'),
        _docInfoJson = lib.lookupFunction<Pointer<Utf8> Function(Pointer<CreDoc>),
            Pointer<Utf8> Function(Pointer<CreDoc>)>('cre_doc_info_json'),
        _docTocJson = lib.lookupFunction<Pointer<Utf8> Function(Pointer<CreDoc>),
            Pointer<Utf8> Function(Pointer<CreDoc>)>('cre_doc_toc_json'),
        docDraw = lib.lookupFunction<Int32 Function(Pointer<CreDoc>, Pointer<Uint8>, Int32, Int32),
            int Function(Pointer<CreDoc>, Pointer<Uint8>, int, int)>('cre_doc_draw'),
        docDrawPage = lib.lookupFunction<Int32 Function(Pointer<CreDoc>, Int32, Pointer<Uint8>, Int32, Int32, Int32),
            int Function(Pointer<CreDoc>, int, Pointer<Uint8>, int, int, int)>('cre_doc_draw_page'),
        docRequestRender = lib.lookupFunction<Void Function(Pointer<CreDoc>), void Function(Pointer<CreDoc>)>(
            'cre_doc_request_render'),
        _fontFacesJson = lib.lookupFunction<Pointer<Utf8> Function(), Pointer<Utf8> Function()>(
            'cre_font_faces_json'),
        _free = lib.lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>('cre_free');

  /// Opens the native library for the current platform.
  /// Android loads the shared library from jniLibs. iOS links it statically.
  static CreBindings load() {
    final lib = Platform.isAndroid ? DynamicLibrary.open('libcre_ffi.so') : DynamicLibrary.process();
    return CreBindings(lib);
  }

  final int Function() ffiVersion;
  final int Function(Pointer<Utf8>, int, Pointer<Utf8>) _init;
  final int Function(Pointer<Utf8>) _registerFont;
  final void Function(Pointer<Utf8>) _fontsDone;
  final int Function() latestDomVersion;
  final Pointer<CreDoc> Function(int, int) docNew;
  final void Function(Pointer<CreDoc>) docFree;
  final void Function(Pointer<CreDoc>, int) docApplyDefaults;
  final void Function(Pointer<CreDoc>, Pointer<Utf8>, int) _docSetInt;
  final void Function(Pointer<CreDoc>, Pointer<Utf8>, Pointer<Utf8>) _docSetString;
  final void Function(Pointer<CreDoc>, Pointer<Utf8>, Pointer<Utf8>) _docSetStylesheet;
  final void Function(Pointer<CreDoc>, Pointer<Utf8>) _docSetFontFace;
  final void Function(Pointer<CreDoc>, int) docSetFontSize;
  final void Function(Pointer<CreDoc>, int) docSetInterline;
  final void Function(Pointer<CreDoc>, int, int, int, int) docSetMargins;
  final void Function(Pointer<CreDoc>, int, int) docSetColors;
  final int Function(Pointer<CreDoc>, Pointer<Utf8>) _docLoad;
  final void Function(Pointer<CreDoc>, int, int) docResize;
  final void Function(Pointer<CreDoc>) docRender;
  final int Function(Pointer<CreDoc>) docPageCount;
  final int Function(Pointer<CreDoc>) docCurrentPage;
  final void Function(Pointer<CreDoc>, int) docGotoPage;
  final int Function(Pointer<CreDoc>, Pointer<Utf8>) _docGotoXPointer;
  final Pointer<Utf8> Function(Pointer<CreDoc>) _docGetXPointer;
  final int Function(Pointer<CreDoc>, Pointer<Utf8>) _docPageOfXPointer;
  final int Function(Pointer<CreDoc>) docPercent;
  final Pointer<Utf8> Function(Pointer<CreDoc>, Pointer<Utf8>, int) _docTextAtXPointer;
  final Pointer<Utf8> Function(Pointer<CreDoc>) _docInfoJson;
  final Pointer<Utf8> Function(Pointer<CreDoc>) _docTocJson;
  final int Function(Pointer<CreDoc>, Pointer<Uint8>, int, int) docDraw;
  final int Function(Pointer<CreDoc>, int, Pointer<Uint8>, int, int, int) docDrawPage;
  final void Function(Pointer<CreDoc>) docRequestRender;
  final Pointer<Utf8> Function() _fontFacesJson;
  final void Function(Pointer<Void>) _free;

  String? fontFacesJson() => _take(_fontFacesJson());

  /// Converts a native string that the caller owns, then frees it.
  String? _take(Pointer<Utf8> p) {
    if (p == nullptr) return null;
    final s = p.toDartString();
    _free(p.cast());
    return s;
  }

  bool init(String cacheDir, int cacheSizeMb, String hyphDir) => using(
      (a) => _init(cacheDir.toNativeUtf8(allocator: a), cacheSizeMb, hyphDir.toNativeUtf8(allocator: a)) == 1);

  bool registerFont(String path) => using((a) => _registerFont(path.toNativeUtf8(allocator: a)) == 1);

  void fontsDone(String defaultFace) => using((a) => _fontsDone(defaultFace.toNativeUtf8(allocator: a)));

  void docSetInt(Pointer<CreDoc> d, String name, int value) =>
      using((a) => _docSetInt(d, name.toNativeUtf8(allocator: a), value));

  void docSetString(Pointer<CreDoc> d, String name, String value) =>
      using((a) => _docSetString(d, name.toNativeUtf8(allocator: a), value.toNativeUtf8(allocator: a)));

  void docSetStylesheet(Pointer<CreDoc> d, String cssFile, String extraCss) => using(
      (a) => _docSetStylesheet(d, cssFile.toNativeUtf8(allocator: a), extraCss.toNativeUtf8(allocator: a)));

  void docSetFontFace(Pointer<CreDoc> d, String face) =>
      using((a) => _docSetFontFace(d, face.toNativeUtf8(allocator: a)));

  bool docLoad(Pointer<CreDoc> d, String path) => using((a) => _docLoad(d, path.toNativeUtf8(allocator: a)) == 1);

  bool docGotoXPointer(Pointer<CreDoc> d, String xp) =>
      using((a) => _docGotoXPointer(d, xp.toNativeUtf8(allocator: a)) == 1);

  String? docGetXPointer(Pointer<CreDoc> d) => _take(_docGetXPointer(d));

  int docPageOfXPointer(Pointer<CreDoc> d, String xp) =>
      using((a) => _docPageOfXPointer(d, xp.toNativeUtf8(allocator: a)));

  String? docTextAtXPointer(Pointer<CreDoc> d, String xp, int maxChars) =>
      using((a) => _take(_docTextAtXPointer(d, xp.toNativeUtf8(allocator: a), maxChars)));

  String? docInfoJson(Pointer<CreDoc> d) => _take(_docInfoJson(d));

  String? docTocJson(Pointer<CreDoc> d) => _take(_docTocJson(d));
}
