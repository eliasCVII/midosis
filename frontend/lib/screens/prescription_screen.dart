import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/region_selection_dialog.dart';
import '../widgets/cenabast_autocomplete_field.dart';


class PrescriptionScreen extends StatefulWidget {
  const PrescriptionScreen({super.key});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _MedicationFormItem {
  final TextEditingController nombreCtrl;
  final TextEditingController frecuenciaCtrl;
  final TextEditingController duracionCtrl;
  final TextEditingController horaCtrl;

  _MedicationFormItem({
    String nombre = '',
    int frecuencia = 8,
    int duracion = 7,
    String hora = '08:00',
  })  : nombreCtrl = TextEditingController(text: nombre),
        frecuenciaCtrl = TextEditingController(text: frecuencia.toString()),
        duracionCtrl = TextEditingController(text: duracion.toString()),
        horaCtrl = TextEditingController(text: hora);

  Map<String, dynamic> toMap() {
    return {
      'Nombre': nombreCtrl.text.trim(),
      'FrecuenciaHoras': int.tryParse(frecuenciaCtrl.text.trim()) ?? 8,
      'DuracionDias': int.tryParse(duracionCtrl.text.trim()) ?? 7,
      'HoraInicio': horaCtrl.text.trim(),
    };
  }

  void dispose() {
    nombreCtrl.dispose();
    frecuenciaCtrl.dispose();
    duracionCtrl.dispose();
    horaCtrl.dispose();
  }
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  int _selectedPath = 0; // 0: Manual, 1: Escanear Foto, 2: Leer PDF
  final _formKey = GlobalKey<FormState>();

  final List<_MedicationFormItem> _medicationItems = [
    _MedicationFormItem()
  ];

  bool _isSubmitting = false;
  bool _isProcessingFile = false;

  String? _selectedImageName;
  String? _selectedPdfName;

  List<ItemCalendarioModel> _registeredMedications = [];
  bool _isLoadingList = false;

  @override
  void initState() {
    super.initState();
    _loadRegisteredMedications();
  }

  @override
  void dispose() {
    for (var item in _medicationItems) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRegisteredMedications() async {
    setState(() => _isLoadingList = true);
    final items = await ApiService.getCalendar(pacienteId: 'demo');
    setState(() {
      _registeredMedications = items;
      _isLoadingList = false;
    });
  }

  void _addMedicationItem({String nombre = '', int frec = 8, int dur = 7, String hora = '08:00'}) {
    setState(() {
      _medicationItems.add(_MedicationFormItem(
        nombre: nombre,
        frecuencia: frec,
        duracion: dur,
        hora: hora,
      ));
    });
  }

  void _removeMedicationItem(int index) {
    if (_medicationItems.length <= 1) return;
    setState(() {
      final item = _medicationItems.removeAt(index);
      item.dispose();
    });
  }

  void _populateMedications(List parsedMeds) {
    setState(() {
      for (var item in _medicationItems) {
        item.dispose();
      }
      _medicationItems.clear();

      if (parsedMeds.isEmpty) {
        _medicationItems.add(_MedicationFormItem());
      } else {
        for (var m in parsedMeds) {
          _medicationItems.add(_MedicationFormItem(
            nombre: m['Nombre'] ?? '',
            frecuencia: m['FrecuenciaHoras'] ?? 8,
            duracion: m['DuracionDias'] ?? 7,
            hora: m['HoraInicio'] ?? '08:00',
          ));
        }
      }
    });
  }

  Future<void> _pickAndProcessImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;

      final file = result.files.first;
      final imageBytes = file.bytes!;
      _selectedImageName = file.name;

      if (!mounted) return;

      // Open freehand drawing rectangle selection dialog
      final cropResult = await showDialog<dynamic>(
        context: context,
        builder: (ctx) => RegionSelectionDialog(imageBytes: imageBytes),
      );

      // If user clicked Cancel or closed the dialog without selecting scan option, abort completely
      if (cropResult == 'CANCEL' || cropResult == null || cropResult == false) {
        return;
      }

      setState(() => _isProcessingFile = true);

      Map<String, double>? cropMap;
      if (cropResult is Map<String, double>) {
        cropMap = cropResult;
      } else if (cropResult is Map) {
        cropMap = Map<String, double>.from(cropResult);
      }

      final response = await ApiService.scanPrescriptionImage(
        bytes: imageBytes,
        filename: file.name,
        cropBox: cropMap,
      );


      setState(() => _isProcessingFile = false);
      if (!mounted) return;

      if (response['status'] == 'success' || response['status'] == 'warning') {
        final List meds = response['medications'] ?? [];
        _populateMedications(meds);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prescripción procesada. (${meds.length} medicamento(s) detectado(s))'),
            backgroundColor: const Color(0xFF0284C7),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'No se pudo leer la imagen')),
        );
      }
    } catch (e) {
      setState(() => _isProcessingFile = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar la imagen: $e')),
      );
    }
  }

  Future<void> _pickAndProcessPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty || result.files.first.bytes == null) return;

      final file = result.files.first;
      setState(() {
        _selectedPdfName = file.name;
        _isProcessingFile = true;
      });

      final response = await ApiService.readPrescriptionPdf(
        bytes: file.bytes!,
        filename: file.name,
      );

      setState(() => _isProcessingFile = false);
      if (!mounted) return;

      if (response['status'] == 'success') {
        final List meds = response['medications'] ?? [];
        _populateMedications(meds);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Documento PDF leído exitosamente. (${meds.length} medicamento(s) detectado(s))'),
            backgroundColor: const Color(0xFF0284C7),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['error'] ?? 'Error al leer el archivo PDF')),
        );
      }
    } catch (e) {
      setState(() => _isProcessingFile = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar el PDF: $e')),
      );
    }
  }

  Future<void> _submitPrescription() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final medicationsPayload = _medicationItems.map((item) => item.toMap()).toList();
    final metodo = _selectedPath == 0
        ? 'Manual'
        : _selectedPath == 1
            ? 'Foto'
            : 'PDF';

    try {
      final result = await ApiService.registerPrescription(
        medications: medicationsPayload,
        metodoIngreso: metodo,
      );

      setState(() => _isSubmitting = false);
      if (!mounted) return;

      if (result['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Prescripción guardada exitosamente.'),
            backgroundColor: Colors.green.shade700,
          ),
        );

        // Reset form
        setState(() {
          for (var item in _medicationItems) {
            item.dispose();
          }
          _medicationItems.clear();
          _medicationItems.add(_MedicationFormItem());
          _selectedImageName = null;
          _selectedPdfName = null;
        });

        // Reload calendar list
        _loadRegisteredMedications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'No se pudo guardar la receta')),
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

  Future<void> _confirmDeleteMedication(ItemCalendarioModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Medicamento'),
        content: Text('¿Está seguro de que desea eliminar "${item.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteItem('demo', item.idItemCalendario);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Medicamento "${item.nombre}" eliminado.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        _loadRegisteredMedications();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar el medicamento.')),
        );
      }
    }
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
            'Ingrese o escanee sus medicamentos para agendarlos automáticamente.',
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
                  onSelected: (val) => setState(() => _selectedPath = 1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Text('Subir PDF'),
                  selected: _selectedPath == 2,
                  onSelected: (val) => setState(() => _selectedPath = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // PATH 1: Escanear Foto (with Image Picker & Drawing Dialog)
          if (_selectedPath == 1) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.camera_alt, color: Color(0xFF0284C7)),
                        SizedBox(width: 8),
                        Text(
                          'Escanear Foto de Receta',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                        onPressed: _isProcessingFile ? null : _pickAndProcessImage,
                        icon: _isProcessingFile
                            ? const SizedBox.shrink()
                            : const Icon(Icons.crop_free, color: Colors.white),
                        label: _isProcessingFile
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(_selectedImageName == null ? 'Seleccionar Foto y Enmarcar Área' : 'Cambiar Foto ($_selectedImageName)', style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // PATH 2: Subir PDF
          if (_selectedPath == 2) ...[
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.picture_as_pdf, color: Color(0xFF0284C7)),
                        SizedBox(width: 8),
                        Text(
                          'Cargar Documento PDF',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                        onPressed: _isProcessingFile ? null : _pickAndProcessPdf,
                        icon: _isProcessingFile
                            ? const SizedBox.shrink()
                            : const Icon(Icons.upload_file, color: Colors.white),
                        label: _isProcessingFile
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(_selectedPdfName == null ? 'Subir y Leer Archivo PDF' : 'Cambiar PDF ($_selectedPdfName)', style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // FORM: Multi-Medication Review / Validation Form
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedPath == 0
                              ? 'Medicamentos de la Receta'
                              : 'Revisar y Confirmar Medicamentos',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: () => _addMedicationItem(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Agregar otro'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Render editable item card for each detected/added medication
                    ..._medicationItems.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Medicamento ${idx + 1}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                ),
                                if (_medicationItems.length > 1)
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => _removeMedicationItem(idx),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            CenabastAutocompleteField(
                              controller: item.nombreCtrl,
                              labelText: 'Nombre del medicamento',
                              validator: (val) => val == null || val.trim().isEmpty ? 'Ingrese el nombre del medicamento' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: item.frecuenciaCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Cada cuántas horas',
                                      prefixIcon: Icon(Icons.access_time),
                                      border: OutlineInputBorder(),
                                      isDense: true,
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
                                    controller: item.duracionCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Por cuántos días',
                                      prefixIcon: Icon(Icons.calendar_month),
                                      border: OutlineInputBorder(),
                                      isDense: true,
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
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: item.horaCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Hora de inicio de consumo (HH:MM)',
                                prefixIcon: Icon(Icons.schedule),
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSubmitting ? null : _submitPrescription,
                        icon: _isSubmitting
                            ? const SizedBox.shrink()
                            : const Icon(Icons.check_circle, color: Colors.white),
                        label: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Guardar Prescripción', style: TextStyle(fontSize: 16, color: Colors.white)),
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
                    'Medicamentos Registrados (${_registeredMedications.length})',
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
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _confirmDeleteMedication(item),
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}

