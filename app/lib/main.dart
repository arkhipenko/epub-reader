import 'package:flutter/material.dart';

import 'spike/home_screen.dart';

void main() {
  runApp(const EpubReaderApp());
}

class EpubReaderApp extends StatelessWidget {
  const EpubReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'epub-reader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Koodo Reader "Blue" accent.
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0179CA)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
