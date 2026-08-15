import 'package:flutter/material.dart';
import 'prescription_screen.dart';
import 'calendar_screen.dart';
import 'medication_info_screen.dart';
import 'notes_screen.dart';
import 'sync_screen.dart';
import 'admin_screen.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../widgets/auth_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const PrescriptionScreen(),
      const CalendarScreen(),
      const MedicationInfoScreen(),
      const NotesScreen(),
      const SyncScreen(),
    ];

    return ValueListenableBuilder<UsuarioModel?>(
      valueListenable: AuthService.currentUserNotifier,
      builder: (context, user, _) {
        final isAdmin = user?.rol == 'administrador';

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
              if (user == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white70),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    icon: const Icon(Icons.account_circle, size: 18),
                    label: const Text('Ingresar', style: TextStyle(fontSize: 13)),
                    onPressed: () => AuthDialog.show(context),
                  ),
                )
              else
                InkWell(
                  onTap: () => AuthDialog.show(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.white,
                          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                          child: user.photoUrl == null
                              ? Text(
                                  user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7), fontSize: 13),
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          user.nombre.split(' ').first,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade400,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 8),
            ],
            backgroundColor: const Color(0xFF0284C7),
            elevation: 2,
          ),
          body: SafeArea(
            child: isAdmin ? const AdminScreen() : pages[_currentIndex],
          ),
          bottomNavigationBar: isAdmin
              ? null
              : NavigationBar(
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
      },
    );
  }
}
