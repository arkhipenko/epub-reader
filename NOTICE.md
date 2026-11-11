# Notices

KOReader Mobile (this repository)
Copyright (C) 2026 Anatoli Arkhipenko

License: GNU Affero General Public License, version 3 or (at your option) any later version.
The license text is in `LICENSE`.

The app shows these notices in About ("View licenses"). The license texts that the app shows
are in `app/assets/licenses/`.

## Parts from other projects

Code and design:

| Part | Use in the app | License | Source |
|---|---|---|---|
| KOReader | Rules and logic ported to Dart and C++ (reading position, kosync, partial MD5 book key, style tweaks, default OPDS catalogs), XPointer test data | AGPL-3.0 | https://github.com/koreader/koreader |
| koreader-base | Build system for the engine. `native/ios/koreader-base-ios.patch` changes it. `cre.cpp` is the model for `native/src/cre_ffi.cpp`. | AGPL-3.0; `cre.cpp`: GPL-3.0-or-later | https://github.com/koreader/koreader-base, commit b153a4a252f6e4295af7a569bcfdd59ffa688fa6 |
| Koodo Reader | Layout of the library and the reader, theme colors | AGPL-3.0 | https://github.com/koodo-reader/koodo-reader |

Compiled into the reading engine (`libcre_ffi`):

| Part | Version | License | Source |
|---|---|---|---|
| crengine (KOReader fork), with its CSS files and hyphenation patterns | commit f335f7a97e240f505bb8a0dfb721fcb7912a7824 | GPL (the license text in the crengine tree is version 2). A hyphenation pattern file that states its own license is under that license. | https://github.com/koreader/crengine |
| Antiword (part of crengine) | | GPL | as crengine |
| CHMLib (part of crengine) | | LGPL-2.1 | as crengine |
| qimagescale (part of crengine) | | Imlib2 license (permissive) | as crengine |
| FreeType | 2.15.0 | FreeType License (FTL) | https://freetype.org |
| HarfBuzz | 14.5.1 | MIT ("Old MIT") | https://github.com/harfbuzz/harfbuzz |
| GNU FriBidi | 1.0.18 | LGPL-2.1 | https://github.com/fribidi/fribidi |
| libunibreak | 7.0 | zlib | https://github.com/adah1972/libunibreak |
| libjpeg-turbo | 3.2.0 | IJG, BSD-3-Clause, zlib | https://libjpeg-turbo.org |
| libpng | 1.6.59 | PNG Reference Library License v2 | https://github.com/pnggroup/libpng |
| libwebp | 1.6.0 | BSD-3-Clause | https://chromium.googlesource.com/webm/libwebp |
| LunaSVG, with plutovg | 2.3.9 | MIT (plutovg has code under the FTL) | https://github.com/sammycage/lunasvg |
| MD4C | 0.5.3 | MIT | https://github.com/mity/md4c |
| utf8proc | 2.12.0 | MIT, Unicode data license | https://github.com/JuliaStrings/utf8proc |
| xxHash | 0.8.4 | BSD-2-Clause | https://github.com/Cyan4973/xxHash |
| Zstandard | 1.5.7 | BSD-3-Clause | https://github.com/facebook/zstd |
| Brotli | 1.2.1 | MIT | https://github.com/google/brotli |
| zlib | 1.4 | zlib | https://zlib.net |
| SRELL | 3.018 | BSD-2-Clause | https://www.akenotsuki.com/misc/srell/en/ |

Fonts (from koreader-fonts, commit 046976988aa33639d60d6ffd25c7a0ff50b72ac0, https://github.com/koreader/koreader-fonts):

| Fonts | License |
|---|---|
| Noto Serif, Noto Sans, Noto Naskh Arabic, Noto UI fonts | SIL Open Font License 1.1 |
| Droid Sans Mono | Apache License 2.0 |
| GNU FreeFont (FreeSerif, FreeSans) | GPL-3.0-or-later, with the GPL font exception |

Flutter, Dart and the pub packages: Flutter collects their licenses at build time, and the app
shows them in About ("View licenses"). The sqlite3 package includes SQLite, which is in the
public domain.

## Source code

The source code of a build is:
- This repository at the commit of the build.
- koreader-base, crengine and koreader-fonts at the commits above. The build scripts
  (`native/build-android.sh`, `native/build-ios.sh`) get them from GitHub.
- The library sources at the versions above. The koreader-base build downloads them
  (see `thirdparty/*/CMakeLists.txt` in koreader-base).
