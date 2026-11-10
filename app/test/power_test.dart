import 'package:epub_reader/reader/power.dart';
import 'package:epub_reader/reader/reader_settings.dart';
import 'package:epub_reader/reader/reader_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pre-rendering', () {
    test('only the page in the reading direction', () {
      expect(pagesToPrefetch(current: 10, direction: 1, pageCount: 100), [11]);
      expect(pagesToPrefetch(current: 10, direction: -1, pageCount: 100), [9]);
    });

    test('nothing past the ends, nothing in battery saver mode', () {
      expect(pagesToPrefetch(current: 100, direction: 1, pageCount: 100), isEmpty);
      expect(pagesToPrefetch(current: 1, direction: -1, pageCount: 100), isEmpty);
      expect(pagesToPrefetch(current: 10, direction: 1, pageCount: 100, saver: true), isEmpty);
    });

    test('the page the reader came from stays cached', () {
      expect(pagesToKeep(10), {9, 10, 11});
    });
  });

  test('pull on return only after 5 minutes away', () {
    final now = DateTime(2026, 11, 9, 12);
    expect(shouldPullOnResume(pausedAt: null, now: now), isTrue);
    expect(shouldPullOnResume(pausedAt: now.subtract(const Duration(minutes: 2)), now: now), isFalse);
    expect(shouldPullOnResume(pausedAt: now.subtract(const Duration(minutes: 5)), now: now), isTrue);
  });

  test('rescan on return only when access is new or the last scan is old', () {
    final now = DateTime(2026, 11, 9, 12);
    final recent = now.subtract(const Duration(hours: 1));
    expect(shouldRescanOnResume(lastScan: recent, now: now, accessGranted: false), isFalse);
    expect(shouldRescanOnResume(lastScan: recent, now: now, accessGranted: true), isTrue);
    expect(
      shouldRescanOnResume(lastScan: now.subtract(const Duration(hours: 7)), now: now, accessGranted: false),
      isTrue,
    );
    expect(shouldRescanOnResume(lastScan: null, now: now, accessGranted: false), isTrue);
  });

  test('status line refresh is slower in battery saver mode', () {
    expect(footerInterval(saver: false), const Duration(seconds: 30));
    expect(footerInterval(saver: true), const Duration(minutes: 1));
  });

  test('brightness and screen timeout settings round trip and clamp', () {
    const s = ReaderSettings(brightness: 0.3, screenTimeoutMinutes: 10);
    final r = ReaderSettings.decode(s.encode());
    expect(r.brightness, 0.3);
    expect(r.screenTimeoutMinutes, 10);
    expect(const ReaderSettings().brightness, isNull); // system brightness
    expect(const ReaderSettings().screenTimeoutMinutes, 0); // system timeout, no wake lock
    expect(ReaderSettings.decode('{"brightness": 3}').brightness, 1.0);
    expect(s.copyWith(brightness: () => null).brightness, isNull);
    expect(s.layoutDiffers(s.copyWith(brightness: () => 0.9, screenTimeoutMinutes: 30)), isFalse);
  });

  test('black OLED theme maps white to pure black', () {
    final t = readerThemeById('black');
    expect(t.isDark, isTrue);
    final m = t.darkMatrix;
    for (var row = 0; row < 3; row++) {
      final out = m[row * 5 + row] * 255 + m[row * 5 + 4];
      expect(out.round(), 0);
    }
  });
}
