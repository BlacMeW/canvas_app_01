import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'solar_system_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MyApp());
  // Set Windows/Linux app window title if possible
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // ignore: undefined_prefixed_name
    SystemChrome.setApplicationSwitcherDescription(
      const ApplicationSwitcherDescription(
        label: 'Solar System with Jean Meeus',
        primaryColor: 0xFF512DA8,
      ),
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Solar System with Jean Meeus', // Sets app title for Android/iOS and web
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const SolarSystemPage(),
    );
  }
}

// TrigCirclePage and TrigCirclePainter are now in trig_circle_page.dart
