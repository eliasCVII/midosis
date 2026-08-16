import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  String? _generatedCode;
  bool _isGenerating = false;

  final TextEditingController _codeCtrl = TextEditingController();
  List<ItemCalendarioModel> _syncedItems = [];
  bool _isLinking = false;
  String? _linkedPatientName;

  @override
  void initState() {
    super.initState();
    final currentCode = AuthService.currentPaciente?.codigoSincronizacion;
    if (currentCode != null && currentCode.isNotEmpty) {
      _generatedCode = currentCode;
    }
    if (AuthService.isCaregiver && AuthService.linkedPatientIdNotifier.value != null) {
      _loadLinkedCalendar(AuthService.linkedPatientIdNotifier.value!);
    }
    AuthService.currentUserNotifier.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    AuthService.currentUserNotifier.removeListener(_onAuthChanged);
    _codeCtrl.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {
        _generatedCode = AuthService.currentPaciente?.codigoSincronizacion;
      });
    }
  }

  Future<void> _loadLinkedCalendar(String patientId) async {
    final items = await ApiService.getCalendar(pacienteId: patientId);
    if (!mounted) return;
    setState(() {
      _syncedItems = items;
      _linkedPatientName = AuthService.linkedPatientNameNotifier.value ?? patientId;
    });
  }

  Future<void> _generateCode() async {
    setState(() => _isGenerating = true);
    final patientId = AuthService.currentPacienteId;
    final code = await ApiService.generateSyncCode(patientId);
    if (!mounted) return;
    setState(() {
      _generatedCode = code;
      _isGenerating = false;
    });
  }

  Future<void> _linkCalendar() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLinking = true);
    final res = await ApiService.linkSyncCode(code);
    if (!mounted) return;
    setState(() => _isLinking = false);

    if (res['status'] == 'success') {
      final List itemsJson = res['calendario']['Items'] ?? [];
      final patientId = res['paciente']['IdPaciente'] ?? '';
      
      AuthService.linkedPatientIdNotifier.value = patientId;
      AuthService.linkedPatientNameNotifier.value = patientId;

      setState(() {
        _syncedItems = itemsJson.map((i) => ItemCalendarioModel.fromJson(i)).toList();
        _linkedPatientName = patientId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Calendario de paciente sincronizado exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error'] ?? 'Código inválido o expirado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UsuarioModel?>(
      valueListenable: AuthService.currentUserNotifier,
      builder: (context, user, _) {
        final isCaregiver = user?.rol == 'cuidador';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Compartir y Sincronizar Calendarios', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Patient only: Generate sync code
              if (!isCaregiver) ...[
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.share, color: Color(0xFF0284C7)),
                            SizedBox(width: 8),
                            Text('Paciente: Generar Código de Sincronización', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text('Genera un código único para compartir tu calendario con tu cuidador.'),
                        const SizedBox(height: 12),
                        if (_generatedCode != null)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SelectableText(
                                  _generatedCode!,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4,
                                    color: Color(0xFF0284C7),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0284C7),
                                    side: const BorderSide(color: Color(0xFF0284C7)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Copiar'),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: _generatedCode!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('¡Código copiado al portapapeles!'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                          onPressed: _isGenerating ? null : _generateCode,
                          child: _isGenerating
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Generar / Mostrar Código', style: TextStyle(color: Colors.white)),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Caregiver link section
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sync, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Vincular Calendario de Paciente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Ingrese el código de sincronización (ej. K7A-6AT) proporcionado por el paciente.'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _codeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Código de Sincronización',
                          hintText: 'ABC-123',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: _isLinking ? null : _linkCalendar,
                        child: _isLinking
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Sincronizar Calendario', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                ),
              ),
              if (_syncedItems.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Medicamentos del Paciente (${_linkedPatientName ?? "Paciente"})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _syncedItems.length,
                  itemBuilder: (ctx, idx) {
                    final item = _syncedItems[idx];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.medical_services, color: Colors.green),
                        title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Horario: ${item.horaInicio} (c/${item.frecuenciaHoras}h) • Duración: ${item.duracionDias} días'),
                      ),
                    );
                  },
                )
              ]
            ],
          ),
        );
      },
    );
  }
}
