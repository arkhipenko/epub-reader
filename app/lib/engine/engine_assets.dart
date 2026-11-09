// Copies the engine data (fonts, CSS, hyphenation patterns) from the app
// bundle to the file system, because crengine reads them by path.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

const String _assetPrefix = 'assets/engine/';

/// Increase this when the bundled engine data changes, so that the next
/// start copies it again.
const String _engineDataVersion = '1';

class EnginePaths {
  const EnginePaths({required this.dataDir, required this.cacheDir});

  final String dataDir;
  final String cacheDir;
}

Future<EnginePaths> prepareEngineData() async {
  final support = await getApplicationSupportDirectory();
  final cache = await getApplicationCacheDirectory();
  final dataDir = Directory('${support.path}/engine');
  final stamp = File('${dataDir.path}/.version');

  final upToDate = await stamp.exists() && (await stamp.readAsString()) == _engineDataVersion;
  if (!upToDate) {
    if (await dataDir.exists()) await dataDir.delete(recursive: true);
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final keys = manifest.listAssets().where((k) => k.startsWith(_assetPrefix));
    for (final key in keys) {
      final bytes = await rootBundle.load(key);
      final file = File('${dataDir.path}/${key.substring(_assetPrefix.length)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes), flush: true);
    }
    await stamp.writeAsString(_engineDataVersion, flush: true);
  }
  return EnginePaths(dataDir: dataDir.path, cacheDir: '${cache.path}/cr3cache');
}
