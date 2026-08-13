import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

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
  }

  Future<void> _loadNotesAndCalendar() async {
    setState(() => _isLoading = true);
    final notes = await ApiService.getNotes('demo');
    final calItems = await ApiService.getCalendar(pacienteId: 'demo');
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

    final ok = await ApiService.addNote(
      pacienteId: 'demo',
      medicamentoId: _selectedMedicationId,
      descripcion: text,
    );

    if (ok) {
      _descCtrl.clear();
      setState(() => _selectedMedicationId = null);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nota registrada exitosamente')));
      _loadNotesAndCalendar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registrar Notas de Efectos Secundarios', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
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
                    onPressed: _addNote,
                    icon: const Icon(Icons.add_comment),
                    label: const Text('Guardar Nota'),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Mis Notas Registradas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notes.isEmpty
                    ? const Center(child: Text('No hay notas registradas.'))
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
