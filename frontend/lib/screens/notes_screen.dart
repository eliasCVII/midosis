import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<NotaModel> _notes = [];
  List<ItemCalendarioModel> _calendarItems = [];
  bool _isLoading = true;

  String? _selectedMedicationId;
  final TextEditingController _descCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotesAndCalendar();
    AuthService.currentUserNotifier.addListener(_loadNotesAndCalendar);
    AuthService.currentPacienteNotifier.addListener(_loadNotesAndCalendar);
    AuthService.linkedPatientIdNotifier.addListener(_loadNotesAndCalendar);
  }

  @override
  void dispose() {
    AuthService.currentUserNotifier.removeListener(_loadNotesAndCalendar);
    AuthService.currentPacienteNotifier.removeListener(_loadNotesAndCalendar);
    AuthService.linkedPatientIdNotifier.removeListener(_loadNotesAndCalendar);
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadNotesAndCalendar() async {
    setState(() => _isLoading = true);
    final patientId = AuthService.currentPacienteId;
    if (patientId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _notes = [];
        _calendarItems = [];
        _isLoading = false;
      });
      return;
    }
    final notes = await ApiService.getNotes(patientId);
    final calItems = await ApiService.getCalendar(pacienteId: patientId);
    if (!mounted) return;
    setState(() {
      _notes = notes;
      _calendarItems = calItems;
      _isLoading = false;
    });
  }

  Future<void> _addNote() async {
    final text = _descCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese la descripción del síntoma')));
      return;
    }

    final patientId = AuthService.currentPacienteId;
    final ok = await ApiService.addNote(
      pacienteId: patientId,
      medicamentoId: _selectedMedicationId,
      descripcion: text,
    );

    if (ok) {
      _descCtrl.clear();
      setState(() => _selectedMedicationId = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nota registrada exitosamente')));
      _loadNotesAndCalendar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCaregiver = AuthService.isCaregiver;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCaregiver ? 'Notas de Síntomas del Paciente' : 'Registrar Notas de Efectos Secundarios',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Only patient can add new notes (Caregiver is read-only)
          if (!isCaregiver) ...[
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Asociar a Medicamento (Opcional):', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String?>(
                      isExpanded: true,
                      value: _selectedMedicationId,
                      hint: const Text('Ninguno específico'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Ninguno específico')),
                        ..._calendarItems.map(
                          (item) => DropdownMenuItem<String?>(
                            value: item.idMedicamento,
                            child: Text(item.nombre),
                          ),
                        )
                      ],
                      onChanged: (val) => setState(() => _selectedMedicationId = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Describa los efectos secundarios o síntomas observados...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                      onPressed: _addNote,
                      icon: const Icon(Icons.add_comment, color: Colors.white),
                      label: const Text('Guardar Nota', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          Text(
            isCaregiver ? 'Historial de Notas Registradas por el Paciente' : 'Mis Notas Registradas',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? Center(
                        child: Text(
                          isCaregiver
                              ? 'El paciente no ha registrado notas de efectos secundarios todavía.'
                              : 'No hay notas registradas.',
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _notes.length,
                        itemBuilder: (ctx, idx) {
                          final note = _notes[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: const Icon(Icons.note_alt, color: Colors.orange),
                              title: Text(note.descripcion),
                              subtitle: Text('Medicamento: ${note.nombreMedicamento} • ${note.fecha ?? ""}'),
                            ),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }
}
