import 'package:flutter/material.dart';
import 'prescription_screen.dart';
import 'calendar_screen.dart';
import 'medication_info_screen.dart';
import 'notes_screen.dart';
import 'sync_screen.dart';

import 'admin_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _showAdminScreen = false;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const PrescriptionScreen(),
      const CalendarScreen(),
      const MedicationInfoScreen(),
      const NotesScreen(),
      const SyncScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.medication_liquid, color: Color(0xFF0284C7)),
            ),
            const SizedBox(width: 10),
            const Text(
              'MiDosis',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showAdminScreen ? Icons.person : Icons.admin_panel_settings,
              color: Colors.white,
            ),
            tooltip: _showAdminScreen ? 'Modo Paciente' : 'Modo Administrador',
            onPressed: () {
              setState(() {
                _showAdminScreen = !_showAdminScreen;
              });
            },
          ),
        ],
        backgroundColor: const Color(0xFF0284C7),
        elevation: 2,
      ),
      body: SafeArea(
        child: _showAdminScreen ? const AdminScreen() : pages[_currentIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.add_task), label: 'Recetas'),
          NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Calendario'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Medicamentos'),
          NavigationDestination(icon: Icon(Icons.note_alt), label: 'Notas'),
          NavigationDestination(icon: Icon(Icons.sync), label: 'Sincronizar'),
        ],
      ),
    );
  }
}
