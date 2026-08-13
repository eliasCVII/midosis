import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  int _selectedPath = 0; // 0: Manual, 1: Escanear Foto, 2: Leer PDF
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _frecuenciaCtrl = TextEditingController(text: "8");
  final TextEditingController _duracionCtrl = TextEditingController(text: "7");
  final TextEditingController _horaCtrl = TextEditingController(text: "08:00");

  bool _isSubmitting = false;
  List<ItemCalendarioModel> _registeredMedications = [];
  bool _isLoadingList = false;

  @override
  void initState() {
    super.initState();
    _loadRegisteredMedications();
  }

  Future<void> _loadRegisteredMedications() async {
    setState(() => _isLoadingList = true);
    final items = await ApiService.getCalendar(pacienteId: 'demo');
    setState(() {
      _registeredMedications = items;
      _isLoadingList = false;
    });
  }

  Future<void> _submitManual() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final nombre = _nombreCtrl.text.trim();
    final frec = int.tryParse(_frecuenciaCtrl.text.trim()) ?? 8;
    final dur = int.tryParse(_duracionCtrl.text.trim()) ?? 7;
    final hora = _horaCtrl.text.trim();

    try {
      final result = await ApiService.registerManualPrescription(
        nombre: nombre,
        frecuenciaHoras: frec,
        duracionDias: dur,
        horaInicio: hora,
      );

      setState(() => _isSubmitting = false);
      if (!mounted) return;

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Medicamento "$nombre" guardado exitosamente en MySQL!')),
        );

        // Reset form for next medication entry
        _nombreCtrl.clear();
        _frecuenciaCtrl.text = "8";
        _duracionCtrl.text = "7";
        _horaCtrl.text = "08:00";

        // Reload database items
        _loadRegisteredMedications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Error al registrar receta')),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar con el servidor: $e')),
      );
    }
  }

  void _simulateScanOrPdf(String method) {
    setState(() {
      _nombreCtrl.text = method == 'Foto' ? 'Amoxicilina 500mg' : 'Ibuprofeno 400mg';
      _frecuenciaCtrl.text = '8';
      _duracionCtrl.text = '7';
      _horaCtrl.text = '08:00';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Prescripción procesada ($method). Por favor revise y confirme los datos.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registrar Receta Médica',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingrese o escanee sus medicamentos. Todos los datos se guardan permanentemente en la base de datos.',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('Ingreso Manual'),
                  selected: _selectedPath == 0,
                  onSelected: (val) => setState(() => _selectedPath = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Escanear Foto'),
                  selected: _selectedPath == 1,
                  onSelected: (val) {
                    setState(() => _selectedPath = 1);
                    _simulateScanOrPdf('Foto');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Subir PDF'),
                  selected: _selectedPath == 2,
                  onSelected: (val) {
                    setState(() => _selectedPath = 2);
                    _simulateScanOrPdf('PDF');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPath == 0
                          ? 'Ingresar Datos del Medicamento'
                          : 'Validar Información Extraída',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre remedio',
                        prefixIcon: Icon(Icons.medication),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Ingrese el nombre' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _frecuenciaCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Frecuencia (Horas)',
                              prefixIcon: Icon(Icons.access_time),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              final num = int.tryParse(val ?? '');
                              if (num == null || num <= 0) return 'Mayor a 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _duracionCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duración (Días)',
                              prefixIcon: Icon(Icons.calendar_month),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              final num = int.tryParse(val ?? '');
                              if (num == null || num <= 0) return 'Mayor a 0';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _horaCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Hora de inicio de consumo (HH:MM)',
                        prefixIcon: Icon(Icons.schedule),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSubmitting ? null : _submitManual,
                        icon: _isSubmitting
                            ? const SizedBox.shrink()
                            : const Icon(Icons.add, color: Colors.white),
                        label: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Guardar Medicamento', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.medication, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Text(
                    'Medicamentos (${_registeredMedications.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(onPressed: _loadRegisteredMedications, icon: const Icon(Icons.refresh)),
            ],
          ),
          const SizedBox(height: 12),
          _isLoadingList
              ? const Center(child: CircularProgressIndicator())
              : _registeredMedications.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: const Center(
                        child: Text(
                          'No hay medicamentos registrados.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _registeredMedications.length,
                      itemBuilder: (ctx, idx) {
                        final item = _registeredMedications[idx];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE0F2FE),
                              child: Icon(Icons.medical_services, color: Color(0xFF0284C7)),
                            ),
                            title: Text(item.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Hora: ${item.horaInicio} • Cada ${item.frecuenciaHoras} hrs • Durante ${item.duracionDias} días'),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
