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
              else ...[
                if (!isAdmin) ...[
                  // Direct Zero-Friction Navbar Role Toggle
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x33000000),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: user.rol == 'paciente'
                              ? null
                              : () => AuthService.switchRole('paciente'),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: user.rol == 'paciente' ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 14,
                                  color: user.rol == 'paciente' ? const Color(0xFF0284C7) : Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Paciente',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: user.rol == 'paciente' ? FontWeight.bold : FontWeight.normal,
                                    color: user.rol == 'paciente' ? const Color(0xFF0284C7) : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: user.rol == 'cuidador'
                              ? null
                              : () => AuthService.switchRole('cuidador'),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(20)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: user.rol == 'cuidador' ? const Color(0xFF10B981) : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.shield_outlined,
                                  size: 14,
                                  color: user.rol == 'cuidador' ? Colors.white : Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Cuidador',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: user.rol == 'cuidador' ? FontWeight.bold : FontWeight.normal,
                                    color: user.rol == 'cuidador' ? Colors.white : Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade600),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.admin_panel_settings, size: 14, color: Colors.black87),
                        SizedBox(width: 4),
                        Text(
                          'ADMIN',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
                // Profile Avatar / Menu
                InkWell(
                  onTap: () => AuthDialog.show(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: CircleAvatar(
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
                  ),
                ),
              ],
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
