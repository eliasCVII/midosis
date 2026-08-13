import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class MedicationInfoScreen extends StatefulWidget {
  const MedicationInfoScreen({super.key});

  @override
  State<MedicationInfoScreen> createState() => _MedicationInfoScreenState();
}

class _MedicationInfoScreenState extends State<MedicationInfoScreen> {
  List<MedicamentoModel> _meds = [];
  bool _isLoading = true;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  Future<void> _fetchMedications([String query = '']) async {
    setState(() => _isLoading = true);
    final list = await ApiService.getMedications(query: query);
    setState(() {
      _meds = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Consultar Información de Medicamentos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre de medicamento...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchCtrl.clear();
                  _fetchMedications();
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (q) => _fetchMedications(q),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _meds.isEmpty
                    ? const Center(child: Text('Información no encontrada / No se registraron medicamentos'))
                    : ListView.builder(
                        itemCount: _meds.length,
                        itemBuilder: (ctx, idx) {
                          final med = _meds[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ExpansionTile(
                              leading: const Icon(Icons.medical_information, color: Color(0xFF0284C7)),
                              title: Text(med.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: const Text('Tocar para ver recomendaciones y efectos secundarios'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('📖 Descripción / Recomendaciones:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(med.descripcion.isNotEmpty ? med.descripcion : 'Sin información disponible'),
                                      const SizedBox(height: 8),
                                      const Text('⚠️ Efectos Secundarios:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                                      Text(med.efectosSecundarios.isNotEmpty ? med.efectosSecundarios : 'No se registraron efectos secundarios'),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
