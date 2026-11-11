/*
 * cre_ffi: plain C interface to crengine for dart:ffi.
 *
 * The engine calls and their order follow the KOReader Lua binding
 * (koreader-base/cre.cpp) and frontend/document/credocument.lua, so that
 * the document model, and with it the XPointers, match KOReader.
 *
 * Copyright (C) 2026 Anatoli Arkhipenko
 * Parts follow koreader-base cre.cpp, Copyright (C) 2012 Hans-Werner Hilse
 * and the KOReader contributors (GPL-3.0-or-later).
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */
#include "cre_ffi.h"

#include <stdlib.h>
#include <string.h>

#include "lvdocview.h"
#include "lvdocviewprops.h"
#include "lvtinydom.h"
#include "lvstring.h"
#include "hyphman.h"

struct CreDoc {
    LVDocView *view;
    ldomDocument *dom;
};

// KOReader ReaderTypeset BLOCK_RENDERING_FLAGS: mode 3 ("web") is the
// default for new books.
static const int BLOCK_RENDERING_FLAGS_WEB = 0x7FFFFFFF;

static char *dup_str(const lString8 &s) {
    char *out = (char *)malloc(s.length() + 1);
    if (!out) return NULL;
    memcpy(out, s.c_str(), s.length());
    out[s.length()] = 0;
    return out;
}

static void json_escape(lString8 &out, const lString32 &value) {
    lString8 u = UnicodeToUtf8(value);
    out << "\"";
    for (int i = 0; i < u.length(); i++) {
        unsigned char c = (unsigned char)u[i];
        switch (c) {
            case '"': out << "\\\""; break;
            case '\\': out << "\\\\"; break;
            case '\n': out << "\\n"; break;
            case '\r': out << "\\r"; break;
            case '\t': out << "\\t"; break;
            default:
                if (c < 0x20) {
                    char buf[8];
                    snprintf(buf, sizeof(buf), "\\u%04x", c);
                    out << buf;
                } else {
                    out.append(1, (char)c);
                }
        }
    }
    out << "\"";
}

static ldomXPointer make_xpointer(CreDoc *doc, const char *xpointer) {
    if (!doc || !doc->dom || !xpointer || !xpointer[0]) return ldomXPointer();
    return doc->dom->createXPointer(Utf8ToUnicode(xpointer));
}

extern "C" {

int cre_ffi_version(void) { return CRE_FFI_VERSION; }

int cre_init(const char *cache_dir, int cache_size_mb, const char *hyph_dir) {
    static bool done = false;
    if (done) return 1;
    InitFontManager(lString8());
    // KOReader defaults: compressed cache, storage size factor 40.
    compressCachedData(true);
    setStorageMaxUncompressedSizeFactor(40);
    if (cache_dir && cache_dir[0]) {
        ldomDocCache::init(Utf8ToUnicode(cache_dir), (lvsize_t)cache_size_mb * 1024 * 1024);
    }
    if (hyph_dir && hyph_dir[0]) {
        HyphMan::initDictionaries(Utf8ToUnicode(hyph_dir));
    }
    done = true;
    return 1;
}

int cre_register_font(const char *path) {
    if (!fontMan || !path) return 0;
    return fontMan->RegisterFont(lString8(path)) ? 1 : 0;
}

void cre_fonts_done(const char *default_face) {
    if (!fontMan) return;
    fontMan->RegularizeRegisteredFontsWeights(false);
    if (default_face && default_face[0]) {
        // Same bias as KOReader CreDocument:engineInit().
        fontMan->SetAsPreferredFontWithBias(lString8(default_face), 1 + 128 * 5 + 256 * 5, true);
    }
}

int cre_latest_dom_version(void) { return gDOMVersionCurrent; }

void cre_set_gamma_index(int index) {
    if (fontMan) fontMan->SetGammaIndex(index);
}

// Writes the cover stream of the loaded document to `out`. Returns true on success.
static bool write_cover(LVDocView *v, const char *out) {
    LVStreamRef stream = v->getCoverPageImageStream();
    if (stream.isNull()) return false;
    lvsize_t size = stream->GetSize();
    if (size == 0) return false;
    uint8_t *buf = (uint8_t *)malloc(size);
    if (!buf) return false;
    lvsize_t read = 0;
    bool ok = stream->Read(buf, size, &read) == LVERR_OK && read == size;
    if (ok) {
        FILE *f = fopen(out, "wb");
        ok = f != NULL && fwrite(buf, 1, size, f) == size;
        if (f) fclose(f);
    }
    free(buf);
    return ok;
}

char *cre_book_info(const char *path, const char *cover_out) {
    if (!path) return NULL;
    LVDocView *v = new LVDocView(-1, true);
    lString32 upath = Utf8ToUnicode(path);
    // KOReader BookInfoManager: loadDocument(false) loads the metadata only.
    if (!v->LoadDocument(upath.c_str(), true)) {
        delete v;
        return NULL;
    }
    bool cover = false;
    if (cover_out && cover_out[0]) {
        cover = write_cover(v, cover_out);
        if (!cover && v->getDocFormat() == doc_format_fb2) {
            // An FB2 cover is a <binary> element after the text, which a
            // metadata-only load does not read. Load the whole file.
            if (v->LoadDocument(upath.c_str(), false)) cover = write_cover(v, cover_out);
        }
    }
    lString8 out("{\"title\":");
    json_escape(out, v->getTitle());
    out << ",\"authors\":";
    json_escape(out, v->getAuthors());
    out << ",\"language\":";
    json_escape(out, v->getLanguage());
    out << ",\"series\":";
    json_escape(out, v->getSeriesName());
    out << ",\"seriesNumber\":" << lString8::itoa(v->getSeriesNumber());
    out << ",\"description\":";
    json_escape(out, v->getDescription());
    out << ",\"format\":";
    json_escape(out, lString32(getDocFormatName(v->getDocFormat())));
    out << ",\"cover\":" << (cover ? "true" : "false") << "}";
    v->close();
    delete v;
    return dup_str(out);
}

int cre_normalized_xpointers_dom_version(void) { return DOM_VERSION_WITH_NORMALIZED_XPOINTERS; }

CreDoc *cre_doc_new(int width, int height) {
    CreDoc *doc = new CreDoc();
    doc->view = new LVDocView(-1, true);  // bitsPerPixel=-1, noDefaultDocument=true
    doc->dom = NULL;
    doc->view->setViewMode(DVM_PAGES, -1);
    doc->view->Resize(width, height);
    // The app draws its own status line.
    doc->view->setPageHeaderInfo(0);
    return doc;
}

void cre_doc_free(CreDoc *doc) {
    if (!doc) return;
    if (doc->view) {
        doc->view->close();  // saves the cache
        delete doc->view;
    }
    delete doc;
}

void cre_doc_apply_defaults(CreDoc *doc, int dpi) {
    if (!doc) return;
    LVDocView *v = doc->view;
    CRPropRef props = v->propsGetCurrent();
    // Fallback defaults from cre.cpp readDefaults() (no cr3.ini present).
    props->setString(PROP_FALLBACK_FONT_FACES, "Noto Sans CJK SC");
    props->setString(PROP_HYPHENATION_DICT, "English_US.pattern");
    props->setString(PROP_STATUS_FONT_FACE, "Noto Sans");
    props->setString(PROP_FONT_FACE, "Noto Serif");
    props->setInt(PROP_FONT_HINTING, 2);
    props->setInt(PROP_FONT_KERNING, 3);
    props->setString("styles.pre.font-face", "font-family: \"Droid Sans Mono\"");
    // credocument.lua setupDefaultView(): no crengine image scaling.
    props->setInt(PROP_IMG_SCALING_ZOOMIN_INLINE_MODE, 0);
    props->setInt(PROP_IMG_SCALING_ZOOMIN_INLINE_SCALE, 1);
    props->setInt(PROP_IMG_SCALING_ZOOMOUT_INLINE_MODE, 0);
    props->setInt(PROP_IMG_SCALING_ZOOMOUT_INLINE_SCALE, 1);
    props->setInt(PROP_IMG_SCALING_ZOOMIN_BLOCK_MODE, 0);
    props->setInt(PROP_IMG_SCALING_ZOOMIN_BLOCK_SCALE, 1);
    props->setInt(PROP_IMG_SCALING_ZOOMOUT_BLOCK_MODE, 0);
    props->setInt(PROP_IMG_SCALING_ZOOMOUT_BLOCK_SCALE, 1);
    props->setInt("crengine.cache.filesize.min", 65536);
    props->setInt("window.pages.two.visible.as.one.page.number", 1);
    // ReaderRolling: new books use the latest DOM version (normalized XPointers).
    props->setInt("crengine.render.requested_dom_version", gDOMVersionCurrent);
    // ReaderTypeset: new books use the "web" block rendering mode.
    props->setInt("crengine.render.block.rendering.flags", BLOCK_RENDERING_FLAGS_WEB);
    // ReaderTypeset: render DPI defaults to 96.
    props->setInt("crengine.render.dpi", 96);
    props->setInt("crengine.doc.embedded.styles.enabled", 1);
    props->setInt("crengine.doc.embedded.fonts.enabled", 1);
    // creoptions.lua status_line: 1 disables the crengine header line
    // (KOReader default). The app draws its own status line.
    props->setInt("window.status.line", 1);
    // KOReader creoptions visible_pages default 1: one column also in
    // landscape (crengine would show two). The app page numbers then map
    // 1:1 to crengine pages.
    props->setInt(PROP_LANDSCAPE_PAGES, 1);
    v->propsApply(props);
    // cre.cpp adjustFontSizes().
    v->setMinFontSize(12);
    v->setMaxFontSize(340);
    v->setStatusFontSize(dpi < 170 ? 20 : (dpi > 250 ? 28 : 24));
}

void cre_doc_set_int(CreDoc *doc, const char *name, int value) {
    if (!doc || !name) return;
    CRPropRef props = LVCreatePropsContainer();
    props->setInt(name, value);
    doc->view->propsApply(props);
}

void cre_doc_set_string(CreDoc *doc, const char *name, const char *value) {
    if (!doc || !name || !value) return;
    CRPropRef props = LVCreatePropsContainer();
    props->setString(name, value);
    doc->view->propsApply(props);
}

void cre_doc_set_stylesheet(CreDoc *doc, const char *css_file, const char *extra_css) {
    if (!doc) return;
    lString8 css;
    if (css_file && css_file[0]) {
        if (!LVLoadStylesheetFile(Utf8ToUnicode(css_file), css)) css = lString8();
    }
    if (extra_css && extra_css[0]) {
        css << "\r\n" << lString8(extra_css);
    }
    doc->view->setStyleSheet(css, false);
}

void cre_doc_set_font_face(CreDoc *doc, const char *face) {
    if (!doc || !face) return;
    doc->view->setDefaultFontFace(lString8(face));
}

void cre_doc_set_font_size(CreDoc *doc, int size_px) {
    if (!doc) return;
    doc->view->setFontSize(size_px);
}

void cre_doc_set_interline(CreDoc *doc, int percent) {
    if (!doc) return;
    doc->view->setDefaultInterlineSpace(percent);
}

void cre_doc_set_margins(CreDoc *doc, int left, int top, int right, int bottom) {
    if (!doc) return;
    lvRect rc;
    rc.left = left;
    rc.top = top;
    rc.right = right;
    rc.bottom = bottom;
    doc->view->setPageMargins(rc);
}

void cre_doc_set_colors(CreDoc *doc, uint32_t background_rgb, uint32_t text_rgb) {
    if (!doc) return;
    doc->view->setBackgroundColor(background_rgb & 0xFFFFFF);
    doc->view->setTextColor(text_rgb & 0xFFFFFF);
}

int cre_doc_load(CreDoc *doc, const char *path) {
    if (!doc || !path) return 0;
    lString32 upath = Utf8ToUnicode(path);
    doc->view->LoadDocument(upath.c_str(), false);
    doc->dom = doc->view->getDocument();
    return doc->dom ? 1 : 0;
}

void cre_doc_resize(CreDoc *doc, int width, int height) {
    if (!doc) return;
    doc->view->Resize(width, height);
}

void cre_doc_render(CreDoc *doc) {
    if (!doc) return;
    doc->view->Render();
}

int cre_doc_page_count(CreDoc *doc) {
    if (!doc) return 0;
    return doc->view->getPageCount(false);
}

int cre_doc_current_page(CreDoc *doc) {
    if (!doc) return 0;
    return doc->view->getCurPage(false) + 1;
}

void cre_doc_goto_page(CreDoc *doc, int page) {
    if (!doc) return;
    doc->view->goToPage(page - 1, false, true, false);
}

int cre_doc_goto_xpointer(CreDoc *doc, const char *xpointer) {
    ldomXPointer xp = make_xpointer(doc, xpointer);
    if (xp.isNull()) return 0;
    doc->view->goToBookmark(xp);
    // As cre.cpp gotoXPointer(): update the position now.
    doc->view->SetPos(xp.toPoint().y);
    return 1;
}

char *cre_doc_get_xpointer(CreDoc *doc) {
    if (!doc || !doc->dom) return NULL;
    ldomXPointer xp = doc->view->getBookmark();
    return dup_str(UnicodeToUtf8(xp.toString()));
}

int cre_doc_page_of_xpointer(CreDoc *doc, const char *xpointer) {
    ldomXPointer xp = make_xpointer(doc, xpointer);
    if (xp.isNull()) return 0;
    // As cre.cpp getPageFromXPointer(): skip to a visible node.
    ldomXPointerEx xpe = xp;
    if (xpe.isText()) xpe.parent();
    if (xpe.getNode()->getRendMethod() == erm_invisible) {
        xpe = xp;
        while (xpe.nextElement()) {
            if (xpe.getNode()->getRendMethod() != erm_invisible) {
                xp = xpe;
                break;
            }
        }
    }
    return doc->view->getBookmarkPage(xp) + 1;
}

int cre_doc_percent(CreDoc *doc) {
    if (!doc) return 0;
    return doc->view->getPosPercent();
}

char *cre_doc_text_at_xpointer(CreDoc *doc, const char *xpointer, int max_chars) {
    ldomXPointer xp = make_xpointer(doc, xpointer);
    if (xp.isNull()) return NULL;
    ldomNode *node = xp.getNode();
    if (!node || node->isNull()) return NULL;
    lString32 text = node->getText();
    if (node->isText()) {
        int offset = xp.getOffset();
        if (offset > 0 && offset < text.length()) text = text.substr(offset);
    }
    if (max_chars > 0 && text.length() > max_chars) text = text.substr(0, max_chars);
    return dup_str(UnicodeToUtf8(text));
}

char *cre_doc_info_json(CreDoc *doc) {
    if (!doc) return NULL;
    LVDocView *v = doc->view;
    lString8 out("{\"title\":");
    json_escape(out, v->getTitle());
    out << ",\"authors\":";
    json_escape(out, v->getAuthors());
    out << ",\"language\":";
    json_escape(out, v->getLanguage());
    out << ",\"series\":";
    json_escape(out, v->getSeries());
    out << ",\"format\":";
    json_escape(out, lString32(getDocFormatName(v->getDocFormat())));
    out << "}";
    return dup_str(out);
}

static void walk_toc(lString8 &out, LVTocItem *toc, bool &first) {
    for (int i = 0; i < toc->getChildCount(); i++) {
        LVTocItem *item = toc->getChild(i);
        if (!first) out << ",";
        first = false;
        out << "{\"title\":";
        json_escape(out, item->getName());
        out << ",\"xpointer\":";
        json_escape(out, item->getPath());
        out << ",\"page\":" << lString8::itoa(item->getPage() + 1);
        out << ",\"depth\":" << lString8::itoa(item->getLevel()) << "}";
        if (item->getChildCount() > 0) walk_toc(out, item, first);
    }
}

char *cre_doc_toc_json(CreDoc *doc) {
    if (!doc || !doc->dom) return NULL;
    lString8 out("[");
    bool first = true;
    LVTocItem *toc = doc->view->getToc();
    if (toc) walk_toc(out, toc, first);
    out << "]";
    return dup_str(out);
}

// crengine gives BGRA with inverted alpha. Convert to RGBA, straight alpha.
static void bgra_to_rgba(uint8_t *p, size_t count) {
    while (count--) {
        uint8_t b = p[0];
        p[0] = p[2];
        p[2] = b;
        p[3] ^= 0xFF;
        p += 4;
    }
}

int cre_doc_draw(CreDoc *doc, uint8_t *rgba, int width, int height) {
    if (!doc || !doc->dom || !rgba || width <= 0 || height <= 0) return 0;
    doc->view->Resize(width, height);
    doc->view->Render();
    LVColorDrawBuf buf(width, height, rgba, 32);
    doc->view->Draw(buf, false);
    bgra_to_rgba(rgba, (size_t)width * height);
    return 1;
}

int cre_doc_draw_page(CreDoc *doc, int page, uint8_t *rgba, int width, int height, int flags) {
    if (!doc || !doc->dom || !rgba || width <= 0 || height <= 0) return 0;
    if (page < 1 || page > doc->view->getPageCount(false)) return 0;
    LVColorDrawBuf buf(width, height, rgba, 32);
    buf.setInvertImages((flags & CRE_DRAW_INVERT_IMAGES) != 0);
    // position -1 and an explicit page: draws that page, the current
    // position does not change.
    doc->view->Draw(buf, -1, page - 1, false, false);
    bgra_to_rgba(rgba, (size_t)width * height);
    return 1;
}

void cre_doc_request_render(CreDoc *doc) {
    if (!doc) return;
    doc->view->requestRender();
}

char *cre_font_faces_json(void) {
    if (!fontMan) return NULL;
    lString32Collection faces;
    fontMan->getFaceList(faces);
    faces.sort();
    lString8 out("[");
    for (int i = 0; i < faces.length(); i++) {
        if (i > 0) out << ",";
        json_escape(out, faces[i]);
    }
    out << "]";
    return dup_str(out);
}

// ---- Text selection, annotations, search, links ----

char *cre_doc_select(CreDoc *doc, int x0, int y0, int x1, int y1) {
    if (!doc || !doc->dom) return NULL;
    LVDocView *v = doc->view;
    lvPoint a(x0, y0), b(x1, y1);
    ldomXPointer pa = v->getNodeByPoint(a, false, true);
    ldomXPointer pb = v->getNodeByPoint(b, false, true);
    if (pa.isNull() || pb.isNull()) return NULL;
    ldomXRange r(pa, pb);
    r.sort();
    const bool swapped = r.getStart().compare(pa) < 0;
    const bool single = r.getStart() == r.getEnd();
    // An XPointer points at the start of a glyph; the end of a selection
    // must point at the start of the next glyph. Same approach as KOReader
    // cre.cpp getTextFromPositions().
    lvRect glyph;
    if (single) {
        lvPoint ref = swapped ? b : a;
        if (v->windowToDocPoint(ref, true) && r.getStart().getRectEx(glyph) && ref.y < glyph.top) {
            // The point is at the end of a line; the hit glyph is on the next line.
            r.getStart().prevVisibleChar(true);
        }
        r.getEnd() = r.getStart();
    } else {
        lvPoint ref = swapped ? a : b;
        int ctx = 0;
        if (r.getEnd().getRectEx(glyph, false, &ctx)) {
            lvPoint gp = glyph.topLeft();
            if (v->docToWindowPoint(gp)) {
                const bool rtl = (ctx & RECT_CTX_IN_RTL_PARA) != 0;
                if (ref.y < gp.y || ref.x < gp.x || (rtl && ref.x >= gp.x + glyph.width())) {
                    r.getEnd().prevVisibleChar(false);
                }
            }
        }
    }
    if (r.getEnd().getChar() != 0) r.getEnd().setOffset(r.getEnd().getOffset() + 1);
    // Grow to whole words.
    if (single) {
        if (!r.getStart().isVisibleWordStart()) r.getStart().prevVisibleWordStart(true);
        if (r.getEnd().isVisibleWordChar() && !r.getEnd().isVisibleWordStart()) r.getEnd().nextVisibleWordEnd(true);
    } else {
        if (r.getStart().isVisibleWordChar() && !r.getStart().isVisibleWordStart()) {
            r.getStart().prevVisibleWordStart(true);
        }
        if (r.getEnd().isVisibleWordChar() && !r.getEnd().isVisibleWordStart()) r.getEnd().nextVisibleWordEnd(true);
    }
    if (r.isNull()) return NULL;
    lString32 text = r.getRangeText('\n', 0);
    lString8 out("{\"text\":");
    json_escape(out, text);
    out << ",\"pos0\":";
    json_escape(out, r.getStart().toString());
    out << ",\"pos1\":";
    json_escape(out, r.getEnd().toString());
    out << "}";
    return dup_str(out);
}

static bool make_range(CreDoc *doc, const char *pos0, const char *pos1, ldomXRange &out) {
    ldomXPointer a = make_xpointer(doc, pos0);
    ldomXPointer b = make_xpointer(doc, pos1);
    if (a.isNull() || b.isNull()) return false;
    out = ldomXRange(a, b);
    out.sort();
    return !out.isNull();
}

char *cre_doc_text_range(CreDoc *doc, const char *pos0, const char *pos1) {
    ldomXRange r;
    if (!make_range(doc, pos0, pos1, r)) return NULL;
    return dup_str(UnicodeToUtf8(r.getRangeText('\n', 0)));
}

// Maps a document rect to the current page. Returns false when the rect is
// not on this page. The rects here are single text lines (segments), and a
// line does not cross a page break, so no clipping is needed.
static bool doc_to_page_rect(LVDocView *v, lvRect &rc) {
    lvPoint tl = rc.topLeft();
    lvPoint br = rc.bottomRight();
    // isRectBottom=true: a bottom edge exactly at the next page top is on this page.
    if (!v->docToWindowPoint(tl) || !v->docToWindowPoint(br, true)) return false;
    rc.setTopLeft(tl);
    rc.setBottomRight(br);
    return true;
}

char *cre_doc_range_boxes(CreDoc *doc, const char *pos0, const char *pos1) {
    if (!doc || !doc->dom) return NULL;
    ldomXRange r;
    lString8 out("[");
    if (make_range(doc, pos0, pos1, r)) {
        LVArray<lvRect> rects;
        r.getSegmentRects(rects, false);
        bool first = true;
        for (int i = 0; i < rects.length(); i++) {
            lvRect rc = rects[i];
            if (rc.isEmpty() || !doc_to_page_rect(doc->view, rc)) continue;
            if (!first) out << ",";
            first = false;
            out << "[" << lString8::itoa(rc.left) << "," << lString8::itoa(rc.top) << "," << lString8::itoa(rc.right)
                << "," << lString8::itoa(rc.bottom) << "]";
        }
    }
    out << "]";
    return dup_str(out);
}

// A few words of text before or after a point, for search results.
static lString32 context_words(const ldomXPointerEx &from, int words, bool before) {
    ldomXPointerEx p = from;
    for (int i = 0; i < words; i++) {
        if (before ? !p.prevVisibleWordStart() : !p.nextVisibleWordEnd()) break;
    }
    ldomXRange r = before ? ldomXRange(p, from) : ldomXRange(from, p);
    return r.getRangeText(' ', 0);
}

char *cre_doc_find_all(CreDoc *doc, const char *pattern, int case_insensitive, int max_hits) {
    if (!doc || !doc->dom || !pattern || !pattern[0]) return NULL;
    ldomXRangeList matches;
    lString8 out("[");
    if (doc->dom->findText(Utf8ToUnicode(pattern), case_insensitive != 0, false, -1, -1, matches, max_hits, -1)) {
        for (int i = 0; i < matches.length(); i++) {
            ldomXRange *m = matches[i];
            if (i > 0) out << ",";
            out << "{\"start\":";
            json_escape(out, m->getStart().toString());
            out << ",\"end\":";
            json_escape(out, m->getEnd().toString());
            out << ",\"page\":" << lString8::itoa(doc->view->getBookmarkPage(m->getStart()) + 1);
            out << ",\"text\":";
            json_escape(out, m->getRangeText(' ', 0));
            out << ",\"before\":";
            json_escape(out, context_words(m->getStart(), 5, true));
            out << ",\"after\":";
            json_escape(out, context_words(m->getEnd(), 5, false));
            out << "}";
        }
    }
    out << "]";
    return dup_str(out);
}

char *cre_doc_link_at(CreDoc *doc, int x, int y) {
    if (!doc || !doc->dom) return NULL;
    lvPoint pt(x, y);
    ldomXPointer p = doc->view->getNodeByPoint(pt, true, false);
    if (p.isNull()) return NULL;
    ldomXPointer a;
    lString32 href = p.getHRef(a);
    if (href.empty()) return NULL;
    lString8 out("{\"href\":");
    json_escape(out, href);
    out << ",\"xpointer\":";
    json_escape(out, a.isNull() ? lString32() : a.toString());
    out << "}";
    return dup_str(out);
}

static void append_boxes(lString8 &out, LVDocView *v, ldomXRange &r) {
    LVArray<lvRect> rects;
    r.getSegmentRects(rects, true);
    out << "[";
    bool first = true;
    for (int i = 0; i < rects.length(); i++) {
        lvRect rc = rects[i];
        if (rc.isEmpty() || !doc_to_page_rect(v, rc)) continue;
        if (!first) out << ",";
        first = false;
        out << "[" << lString8::itoa(rc.left) << "," << lString8::itoa(rc.top) << "," << lString8::itoa(rc.right) << ","
            << lString8::itoa(rc.bottom) << "]";
    }
    out << "]";
}

char *cre_doc_page_links(CreDoc *doc) {
    if (!doc || !doc->dom) return NULL;
    ldomXRangeList links;
    doc->view->getCurrentPageLinks(links);
    lString8 out("[");
    bool first = true;
    for (int i = 0; i < links.length(); i++) {
        ldomXPointer a;
        lString32 href = links[i]->getHRef(a);
        if (href.empty()) continue;
        if (!first) out << ",";
        first = false;
        out << "{\"href\":";
        json_escape(out, href);
        out << ",\"boxes\":";
        append_boxes(out, doc->view, *links[i]);
        out << "}";
    }
    out << "]";
    return dup_str(out);
}

int cre_doc_goto_link(CreDoc *doc, const char *href) {
    if (!doc || !doc->dom || !href || !href[0]) return 0;
    // The app keeps its own back stack (as KOReader ReaderLink does).
    return doc->view->goLink(Utf8ToUnicode(href), false) ? 1 : 0;
}

int cre_doc_compare_xpointers(CreDoc *doc, const char *a, const char *b) {
    ldomXPointerEx pa = make_xpointer(doc, a);
    ldomXPointerEx pb = make_xpointer(doc, b);
    if (pa.isNull() || pb.isNull()) return 0;
    return pa.compare(pb);
}

void cre_free(void *p) { free(p); }

}  // extern "C"
