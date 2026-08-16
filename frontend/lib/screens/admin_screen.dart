import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<MedicamentoModel> _medications = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMedications([String query = '']) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) {
      setState(() {
        _medications = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await ApiService.getMedications(query: cleanQuery);
    if (!mounted) return;
    setState(() {
      _medications = results;
      _isSearching = false;
    });
  }

  void _showEditDialog(MedicamentoModel med) {
    final descCtrl = TextEditingController(
      text: med.descripcion == 'Información del medicamento' ? '' : med.descripcion,
    );
    final efectosCtrl = TextEditingController(
      text: med.efectosSecundarios == 'No registrados' ? '' : med.efectosSecundarios,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_note, color: Color(0xFF0284C7), size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Editar: ${med.nombre}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ID de Registro: ${med.idMedicamento}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                const Text('📖 Descripción / Recomendaciones del Medicamento:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ingrese descripción detallada o recomendaciones de consumo...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('⚠️ Efectos Secundarios y Advertencias:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: efectosCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ingrese posibles reacciones adversas o contraindicaciones...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final newDesc = descCtrl.text.trim().isEmpty ? 'Información del medicamento' : descCtrl.text.trim();
                final newEfectos = efectosCtrl.text.trim().isEmpty ? 'No registrados' : efectosCtrl.text.trim();

                final success = await ApiService.updateMedicationInfo(
                  idMedicamento: med.idMedicamento,
                  descripcion: newDesc,
                  efectosSecundarios: newEfectos,
                );

                if (!mounted) return;
                Navigator.pop(ctx);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Medicamento "${med.nombre}" actualizado exitosamente.'),
                      backgroundColor: Colors.green.shade700,
                    ),
                  );
                  _loadMedications(_searchCtrl.text.trim());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al actualizar el medicamento')),
                  );
                }
              },
              child: const Text('Guardar Cambios', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _reimportCenabast() async {
    setState(() => _isSearching = true);
    final res = await ApiService.importCenabast();
    if (!mounted) return;
    setState(() => _isSearching = false);

    if (res['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Catálogo CENABAST re-sincronizado exitosamente.'),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
      _loadMedications(_searchCtrl.text.trim());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['error'] ?? 'Error al re-sincronizar el catálogo CENABAST')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: Color(0xFF0284C7), size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Panel Administrador - CENABAST',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSearching ? null : _reimportCenabast,
                    icon: const Icon(Icons.sync, size: 16, color: Color(0xFF0284C7)),
                    label: const Text('Re-sincronizar Catálogo', style: TextStyle(color: Color(0xFF0284C7))),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => AuthService.signOut(),
                    icon: const Icon(Icons.logout, size: 16, color: Colors.red),
                    label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Edite las descripciones oficiales, recomendaciones y efectos secundarios de los medicamentos del maestro CENABAST.',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 20),

          // SEARCH BAR
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _loadMedications,
                decoration: InputDecoration(
                  labelText: 'Buscar medicamento en catálogo CENABAST (mínimo 2 letras)',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF0284C7)),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            _loadMedications('');
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // RESULTS LIST
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resultados de búsqueda (${_medications.length})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (_isSearching)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (_searchCtrl.text.trim().length < 2)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.search, size: 40, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text(
                    'Escriba al menos 2 caracteres arriba para buscar y editar medicamentos.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                ],
              ),
            )
          else if (_medications.isEmpty && !_isSearching)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Column(
                children: [
                  Icon(Icons.medication_outlined, size: 40, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text(
                    'No se encontraron medicamentos en el catálogo CENABAST con ese nombre.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _medications.length,
              itemBuilder: (ctx, idx) {
                final med = _medications[idx];
                final hasDesc = med.descripcion.isNotEmpty && med.descripcion != 'Información del medicamento';
                final hasEfectos = med.efectosSecundarios.isNotEmpty && med.efectosSecundarios != 'No registrados';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFE0F2FE),
                              child: Icon(Icons.medication, color: Color(0xFF0284C7)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.nombre,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    'Código: ${med.idMedicamento}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0284C7),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _showEditDialog(med),
                              icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                              label: const Text('Editar', style: TextStyle(color: Colors.white, fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('📖 Descripción: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Expanded(
                              child: Text(
                                hasDesc ? med.descripcion : 'Sin descripción personalizada',
                                style: TextStyle(fontSize: 13, color: hasDesc ? Colors.black87 : Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⚠️ Efectos: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber)),
                            Expanded(
                              child: Text(
                                hasEfectos ? med.efectosSecundarios : 'No registrados',
                                style: TextStyle(fontSize: 13, color: hasEfectos ? Colors.black87 : Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
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
