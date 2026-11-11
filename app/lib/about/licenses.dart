// The license notices that the app shows (About > View licenses).
//
// The Flutter license page already lists Flutter, Dart and the pub packages.
// This file adds the app itself and the parts that are compiled into the
// reading engine or copied into the app assets (fonts, CSS, hyphenation
// patterns). The license texts are in assets/licenses. NOTICE.md in the
// repository root lists the same parts with their versions and sources.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

const String kAppName = 'KOReader Mobile';
const String kCopyright = 'Copyright (C) 2026 Anatoli Arkhipenko';
const String kSourceUrl = 'https://github.com/arkhipenko/epub-reader';

/// The standard GNU AGPL notice for the app.
const String kAppNotice =
    '$kAppName\n'
    '$kCopyright\n\n'
    'This program is free software: you can redistribute it and/or modify it '
    'under the terms of the GNU Affero General Public License as published by '
    'the Free Software Foundation, either version 3 of the License, or (at your '
    'option) any later version.\n\n'
    'This program is distributed in the hope that it will be useful, but '
    'WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY '
    'or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public '
    'License for more details.\n\n'
    'Source code: $kSourceUrl';

/// One part of the app from another project: the names on the license page,
/// a notice (copyright, use in the app), and the license text file.
class LicensePart {
  const LicensePart(this.name, this.notice, this.file);

  final String name;
  final String notice;
  final String file;
}

const List<LicensePart> kLicenseParts = [
  LicensePart(kAppName, kAppNotice, 'AGPL-3.0.txt'),
  LicensePart(
    'KOReader',
    'Parts of this app follow or are ported from KOReader and koreader-base '
        '(https://github.com/koreader). Copyright (C) the KOReader contributors. '
        'GNU Affero General Public License version 3. The engine wrapper follows '
        'koreader-base cre.cpp, Copyright (C) 2012 Hans-Werner Hilse, GNU General '
        'Public License version 3 or later.',
    'AGPL-3.0.txt',
  ),
  LicensePart(
    'Koodo Reader',
    'The layout of the library and the reader, and the theme colors, follow '
        'Koodo Reader (https://github.com/koodo-reader/koodo-reader). '
        'Copyright (C) the Koodo Reader contributors. GNU Affero General Public '
        'License version 3.',
    'AGPL-3.0.txt',
  ),
  LicensePart(
    'crengine',
    'The reading engine: the KOReader fork of the CoolReader engine '
        '(https://github.com/koreader/crengine). Copyright (C) 2000-2011 Vadim '
        'Lopatin, and the CoolReader and KOReader contributors. GNU General '
        'Public License. The app also includes the crengine CSS files and '
        'hyphenation patterns. A pattern file that states its own license in its '
        'header is under that license.',
    'GPL-2.0.txt',
  ),
  LicensePart(
    'Antiword',
    'Part of crengine (Word documents). Copyright (C) 1998-2005 A.J. van Os. '
        'GNU General Public License.',
    'GPL-2.0.txt',
  ),
  LicensePart(
    'CHMLib',
    'Part of crengine (CHM files). By Jed Wing. GNU Lesser General Public '
        'License version 2.1.',
    'LGPL-2.1.txt',
  ),
  LicensePart('qimagescale', 'Part of crengine (image scaling).', 'qimagescale.txt'),
  LicensePart(
    'FreeType',
    'Portions of this software are copyright (C) 2026 The FreeType Project '
        '(www.freetype.org). All rights reserved.',
    'freetype.txt',
  ),
  LicensePart('HarfBuzz', 'Text shaping.', 'harfbuzz.txt'),
  LicensePart('GNU FriBidi', 'Bidirectional text. GNU Lesser General Public License version 2.1.', 'LGPL-2.1.txt'),
  LicensePart('libunibreak', 'Line breaking.', 'libunibreak.txt'),
  LicensePart(
    'libjpeg-turbo',
    'JPEG images. This software is based in part on the work of the '
        'Independent JPEG Group.',
    'libjpeg-turbo.txt',
  ),
  LicensePart('libpng', 'PNG images.', 'libpng.txt'),
  LicensePart('libwebp', 'WebP images.', 'libwebp.txt'),
  LicensePart(
    'LunaSVG',
    'SVG images, with plutovg. plutovg contains code from FreeType (see '
        'FreeType).',
    'lunasvg.txt',
  ),
  LicensePart('MD4C', 'Markdown files.', 'md4c.txt'),
  LicensePart('utf8proc', 'Unicode processing.', 'utf8proc.txt'),
  LicensePart('xxHash', 'Hashing.', 'xxhash.txt'),
  LicensePart('Zstandard', 'Compression.', 'zstd.txt'),
  LicensePart('Brotli', 'Compression (WOFF2 fonts).', 'brotli.txt'),
  LicensePart('zlib', 'Compression.', 'zlib.txt'),
  LicensePart('SRELL', 'Regular expressions.', 'srell.txt'),
  LicensePart(
    'Noto fonts',
    'Noto Serif, Noto Sans, Noto Naskh Arabic and the Noto UI fonts. SIL Open '
        'Font License 1.1.',
    'noto-fonts.txt',
  ),
  LicensePart('Droid Sans Mono', 'Apache License 2.0.', 'droid-fonts.txt'),
  LicensePart(
    'GNU FreeFont',
    'FreeSerif and FreeSans. GNU General Public License version 3 or later, '
        'with the GPL font exception: a document that embeds these fonts does not '
        'by itself come under the GPL. The full exception text is in the font '
        'files.',
    'GPL-3.0.txt',
  ),
];

/// Adds [kLicenseParts] to the Flutter license registry. Call once at start.
void registerLicenses() {
  LicenseRegistry.addLicense(() async* {
    final texts = <String, String>{};
    for (final p in kLicenseParts) {
      final text = texts[p.file] ??= await rootBundle.loadString('assets/licenses/${p.file}');
      yield LicenseEntryWithLineBreaks([p.name], '${p.notice}\n\n$text');
    }
  });
}
