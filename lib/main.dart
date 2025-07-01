import 'package:flutter/material.dart';

import 'solar_system_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const SolarSystemPage(),
    );
  }
}

// TrigCirclePage and TrigCirclePainter are now in trig_circle_page.dart
