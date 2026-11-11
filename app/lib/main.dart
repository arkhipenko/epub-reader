import 'package:flutter/material.dart';

import 'app_services.dart';
import 'library/library_screen.dart';
import 'reader/reader_screen.dart';
import 'reader/reader_settings.dart';
import 'reader/reader_theme.dart';

void main() {
  runApp(const EpubReaderApp());
}

class EpubReaderApp extends StatefulWidget {
  const EpubReaderApp({super.key});

  @override
  State<EpubReaderApp> createState() => _EpubReaderAppState();
}

class _EpubReaderAppState extends State<EpubReaderApp> {
  /// The boot logo shows at least this long when the app starts. A warm
  /// start is otherwise too fast to see it.
  static const Duration _minBootLogo = Duration(milliseconds: 1500);

  late final Future<AppServices> _services = Future.wait<Object?>([
    AppServices.start(),
    Future<void>.delayed(_minBootLogo),
  ]).then((r) => r.first! as AppServices);

  ThemeData _theme(String accentId) =>
      ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: accentById(accentId).color), useMaterial3: true);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppServices>(
      future: _services,
      builder: (context, snapshot) {
        final services = snapshot.data;
        if (services == null) {
          // Boot screen: the full logo while the engine starts. (Android 12
          // and later show only the round app icon on the system splash.)
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _theme('blue'),
            home: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Image.asset('images/logo.png', fit: BoxFit.contain),
                        ),
                        const SizedBox(height: 32),
                        if (snapshot.hasError)
                          Text('The reading engine did not start.\n\n${snapshot.error}')
                        else
                          const SizedBox(width: 160, child: LinearProgressIndicator()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return ServicesScope(
          services: services,
          child: ValueListenableBuilder<ReaderSettings>(
            valueListenable: services.settings,
            builder: (context, settings, _) => MaterialApp(
              title: 'KOReader Mobile',
              debugShowCheckedModeBanner: false,
              theme: _theme(settings.accentId),
              routes: {Navigator.defaultRouteName: (_) => const LibraryScreen()},
              // The library, and on top of it the book that was open when
              // the app closed. Back from that book goes to the library.
              onGenerateInitialRoutes: (_) => [
                MaterialPageRoute<void>(builder: (_) => const LibraryScreen()),
                if (services.resumeBook case final path?)
                  MaterialPageRoute<void>(builder: (_) => ReaderScreen(path: path)),
              ],
            ),
          ),
        );
      },
    );
  }
}
