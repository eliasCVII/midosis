import 'package:flutter/material.dart';
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
  }

  Future<void> _generateCode() async {
    setState(() => _isGenerating = true);
    final patientId = AuthService.currentPacienteId;
    final code = await ApiService.generateSyncCode(patientId);
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
    setState(() => _isLinking = false);

    if (res['status'] == 'success') {
      final List itemsJson = res['calendario']['Items'] ?? [];
      setState(() {
        _syncedItems = itemsJson.map((i) => ItemCalendarioModel.fromJson(i)).toList();
        _linkedPatientName = res['paciente']['IdPaciente'];
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Calendario de paciente sincronizado!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['error'] ?? 'Código inválido o expirado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Compartir y Sincronizar Calendarios', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
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
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                      child: SelectableText(
                        _generatedCode!,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 4, color: Color(0xFF0284C7)),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isGenerating ? null : _generateCode,
                    child: _isGenerating ? const CircularProgressIndicator() : const Text('Generar / Mostrar Código'),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                      Text('Cuidador: Vincular Calendario Compartido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Ingrese el código de sincronización proporcionado por el paciente.'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Código de Sincronización',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _isLinking ? null : _linkCalendar,
                    child: _isLinking ? const CircularProgressIndicator(color: Colors.white) : const Text('Sincronizar', style: TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          ),
          if (_syncedItems.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Calendario Sincronizado (Paciente: ${_linkedPatientName ?? "Paciente"})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
  }
}
