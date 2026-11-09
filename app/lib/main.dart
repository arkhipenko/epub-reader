import 'package:flutter/material.dart';

import 'app_services.dart';
import 'home/home_screen.dart';
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
  late final Future<AppServices> _services = AppServices.start();

  ThemeData _theme(String accentId) => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: accentById(accentId).color),
        useMaterial3: true,
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppServices>(
      future: _services,
      builder: (context, snapshot) {
        final services = snapshot.data;
        if (services == null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _theme('blue'),
            home: Scaffold(
              body: Center(
                child: snapshot.hasError
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('The reading engine did not start.\n\n${snapshot.error}'),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          );
        }
        return ServicesScope(
          services: services,
          child: ValueListenableBuilder<ReaderSettings>(
            valueListenable: services.settings,
            builder: (context, settings, _) => MaterialApp(
              title: 'epub-reader',
              debugShowCheckedModeBanner: false,
              theme: _theme(settings.accentId),
              home: const HomeScreen(),
            ),
          ),
        );
      },
    );
  }
}
