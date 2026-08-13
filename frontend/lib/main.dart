import 'package:flutter/material.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(const MiDosisApp());
}

class MiDosisApp extends StatelessWidget {
  const MiDosisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiDosis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0284C7),
        fontFamily: 'Roboto',
      ),
      home: const MainScreen(),
    );
  }
}
