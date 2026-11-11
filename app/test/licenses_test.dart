import 'dart:io';

import 'package:epub_reader/about/about.dart';
import 'package:epub_reader/about/licenses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('each license part has its license text in assets/licenses', () {
    for (final p in kLicenseParts) {
      final f = File('assets/licenses/${p.file}');
      expect(f.existsSync(), isTrue, reason: '${p.name}: missing ${f.path}');
      expect(f.lengthSync(), greaterThan(200), reason: '${p.name}: ${f.path} is too short');
    }
  });

  test('every file in assets/licenses is used', () {
    final used = {for (final p in kLicenseParts) p.file};
    final files = Directory('assets/licenses').listSync().map((e) => e.uri.pathSegments.last).toSet();
    expect(files, used);
  });

  test('the app license is the repository LICENSE', () {
    expect(File('assets/licenses/AGPL-3.0.txt').readAsStringSync(), File('../LICENSE').readAsStringSync());
  });

  test('the license names are unique', () {
    final names = kLicenseParts.map((p) => p.name).toList();
    expect(names.toSet().length, names.length);
  });

  testWidgets('About shows the legal notices, the source address and the licenses', (tester) async {
    registerLicenses();
    // A tall screen, so that the license page builds all its entries.
    tester.view.physicalSize = const Size(800, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) =>
              TextButton(onPressed: () => showAppAbout(context, '1.0.2 (1)'), child: const Text('open')),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(kAppName), findsOneWidget);
    expect(find.text(kCopyright), findsOneWidget);
    expect(find.textContaining('NO WARRANTY'), findsOneWidget);
    expect(find.textContaining(kSourceUrl), findsOneWidget);

    await tester.tap(find.text('View licenses'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
    await tester.pumpAndSettle();
    for (final name in kLicenseParts.map((p) => p.name)) {
      expect(find.text(name), findsWidgets, reason: name);
    }
  });
}
