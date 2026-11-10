/*
 * cre_ffi: plain C interface to crengine (the KOReader fork) for dart:ffi.
 *
 * Rules:
 * - All strings are UTF-8 and NUL-terminated.
 * - A returned char* is owned by the caller. Free it with cre_free().
 * - Page numbers are 1-based, as in KOReader.
 * - One CreDoc must be used from one thread only. The engine globals
 *   (fonts, hyphenation, cache) are set up once by cre_init().
 */
#ifndef CRE_FFI_H
#define CRE_FFI_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define CRE_API __attribute__((visibility("default")))

/* Version of this C interface. Increase it when a signature changes. */
#define CRE_FFI_VERSION 4

/* Flags for cre_doc_draw_page(). */
#define CRE_DRAW_INVERT_IMAGES 1

typedef struct CreDoc CreDoc;

CRE_API int cre_ffi_version(void);

/* Engine setup. Call once, before any document is created. */
CRE_API int cre_init(const char *cache_dir, int cache_size_mb, const char *hyph_dir);
CRE_API int cre_register_font(const char *path);
/* Call after all fonts are registered. */
CRE_API void cre_fonts_done(const char *default_face);
CRE_API int cre_latest_dom_version(void);
CRE_API int cre_normalized_xpointers_dom_version(void);
/* JSON array of the registered font face names, sorted. */
CRE_API char *cre_font_faces_json(void);

/* Book metadata for the library, without opening the book for reading.
 * Returns JSON {title, authors, language, series, seriesNumber, format,
 * description, cover} or NULL when the engine cannot read the file.
 * When cover_out is not NULL and the book has a cover image, the image file
 * (JPEG, PNG, GIF or SVG, as stored in the book) is written there and
 * "cover" is true. Uses its own view, so a book open for reading is not
 * affected (as KOReader BookInfoManager). */
CRE_API char *cre_book_info(const char *path, const char *cover_out);

/* Document view. */
CRE_API CreDoc *cre_doc_new(int width, int height);
CRE_API void cre_doc_free(CreDoc *doc);

/* Apply the KOReader default view settings. Call before cre_doc_load(). */
CRE_API void cre_doc_apply_defaults(CreDoc *doc, int dpi);
CRE_API void cre_doc_set_int(CreDoc *doc, const char *name, int value);
CRE_API void cre_doc_set_string(CreDoc *doc, const char *name, const char *value);
CRE_API void cre_doc_set_stylesheet(CreDoc *doc, const char *css_file, const char *extra_css);
CRE_API void cre_doc_set_font_face(CreDoc *doc, const char *face);
CRE_API void cre_doc_set_font_size(CreDoc *doc, int size_px);
CRE_API void cre_doc_set_interline(CreDoc *doc, int percent);
CRE_API void cre_doc_set_margins(CreDoc *doc, int left, int top, int right, int bottom);
CRE_API void cre_doc_set_colors(CreDoc *doc, uint32_t background_rgb, uint32_t text_rgb);

/* Returns 1 when the document is loaded, 0 on failure. */
CRE_API int cre_doc_load(CreDoc *doc, const char *path);
CRE_API void cre_doc_resize(CreDoc *doc, int width, int height);
CRE_API void cre_doc_render(CreDoc *doc);
/* Mark the layout as stale after a property change. The next render redoes it. */
CRE_API void cre_doc_request_render(CreDoc *doc);

CRE_API int cre_doc_page_count(CreDoc *doc);
CRE_API int cre_doc_current_page(CreDoc *doc);
CRE_API void cre_doc_goto_page(CreDoc *doc, int page);
/* Returns 1 when the XPointer exists in the document, else 0 (no move). */
CRE_API int cre_doc_goto_xpointer(CreDoc *doc, const char *xpointer);
/* XPointer of the current position (KOReader last_xpointer). */
CRE_API char *cre_doc_get_xpointer(CreDoc *doc);
/* Page that holds the XPointer, or 0 when it is not in the document. */
CRE_API int cre_doc_page_of_xpointer(CreDoc *doc, const char *xpointer);
/* Position percent as crengine reports it: 0 to 10000. */
CRE_API int cre_doc_percent(CreDoc *doc);
/* Text of the node at the XPointer, from the XPointer offset on.
 * Returns NULL when the XPointer is not in the document. */
CRE_API char *cre_doc_text_at_xpointer(CreDoc *doc, const char *xpointer, int max_chars);

/* JSON object: title, authors, language, series, format. */
CRE_API char *cre_doc_info_json(CreDoc *doc);
/* JSON array of {title, xpointer, page, depth}. */
CRE_API char *cre_doc_toc_json(CreDoc *doc);

/* Draw the current page into an RGBA8888 buffer of width * height * 4 bytes.
 * Returns 1 on success. */
CRE_API int cre_doc_draw(CreDoc *doc, uint8_t *rgba, int width, int height);
/* Draw page `page` (1-based) without changing the current position.
 * width and height must be the view size. flags: CRE_DRAW_*.
 * Returns 1 on success, 0 when the page does not exist. */
CRE_API int cre_doc_draw_page(CreDoc *doc, int page, uint8_t *rgba, int width, int height, int flags);

/* ---- Text selection, annotations, search, links (version 4) ----
 * Points and boxes are in page pixels of the current page (the view). */

/* Selects text between two points, grown to whole words (KOReader
 * getTextFromPositions). Equal points select the word at the point.
 * Returns JSON {text, pos0, pos1} or NULL when there is no text there.
 * Does not draw anything into the page. */
CRE_API char *cre_doc_select(CreDoc *doc, int x0, int y0, int x1, int y1);

/* Text between two XPointers, or NULL. */
CRE_API char *cre_doc_text_range(CreDoc *doc, const char *pos0, const char *pos1);

/* Line boxes of the range on the current page: JSON [[l,t,r,b], ...].
 * Empty array when the range is not on the current page. */
CRE_API char *cre_doc_range_boxes(CreDoc *doc, const char *pos0, const char *pos1);

/* Full-text search. JSON [{start, end, page, text, before, after}, ...]
 * with a few words of context before and after each match. */
CRE_API char *cre_doc_find_all(CreDoc *doc, const char *pattern, int case_insensitive, int max_hits);

/* Link at a point: JSON {href, xpointer} or NULL. */
CRE_API char *cre_doc_link_at(CreDoc *doc, int x, int y);

/* Links on the current page: JSON [{href, boxes: [[l,t,r,b], ...]}, ...].
 * Lets the app hit-test taps without a call per tap. */
CRE_API char *cre_doc_page_links(CreDoc *doc);

/* Follows an internal link. Returns 1 when the position changed. */
CRE_API int cre_doc_goto_link(CreDoc *doc, const char *href);

/* Order of two XPointers: <0 when a is before b, 0 when equal, >0 after.
 * Returns 0 when one of them is not in the document. */
CRE_API int cre_doc_compare_xpointers(CreDoc *doc, const char *a, const char *b);

CRE_API void cre_free(void *p);

#ifdef __cplusplus
}
#endif

#endif /* CRE_FFI_H */
