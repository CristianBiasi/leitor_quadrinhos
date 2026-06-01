import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/library_provider.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => LibraryProvider()..loadLibrary(),
      child: const ComicReaderApp(),
    ),
  );
}

class ComicReaderApp extends StatelessWidget {
  const ComicReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CBR Reader',
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}