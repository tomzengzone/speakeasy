import 'package:flutter/material.dart';

import 'app_session.dart';
import 'home_page.dart';

void main() {
  runApp(SpeakEasyApp(session: AppSession()));
}

class SpeakEasyApp extends StatelessWidget {
  const SpeakEasyApp({super.key, required this.session});

  final AppSession session;

  @override
  Widget build(BuildContext context) {
    return AppSessionScope(
      session: session,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SpeakEasy',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A6B57),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF3EFE8),
          textTheme: ThemeData.light().textTheme.apply(
            bodyColor: const Color(0xFF241F1A),
            displayColor: const Color(0xFF241F1A),
          ),
        ),
        home: const SpeakEasyHomePage(),
      ),
    );
  }
}
