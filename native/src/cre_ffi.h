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
#define CRE_FFI_VERSION 2

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

CRE_API void cre_free(void *p);

#ifdef __cplusplus
}
#endif

#endif /* CRE_FFI_H */
