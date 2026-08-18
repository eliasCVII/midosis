import 'package:flutter/material.dart';
import 'screens/main_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Auto-discover backend host (USB adb reverse or local Wi-Fi)
  await ApiService.checkHealth();
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
