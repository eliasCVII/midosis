import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoggedIn = false;
  bool _isLoading = false;

  final TextEditingController _emailCtrl = TextEditingController(text: 'admin@midosis.cl');
  final TextEditingController _passCtrl = TextEditingController(text: 'admin123');
  final TextEditingController _searchCtrl = TextEditingController();

  List<MedicamentoModel> _medications = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loginAdmin() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese sus credenciales de administrador')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isLoading = false;
      _isLoggedIn = true;
      _medications = [];
    });
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
                    hintText: 'Ej: Tomar preferentemente después de las comidas con abundante agua...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('⚠️ Efectos Secundarios / Advertencias:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: efectosCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Ej: Puede causar somnolencia leve o malestar estomacal en pacientes sensibles...',
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
              icon: const Icon(Icons.save, color: Colors.white, size: 18),
              label: const Text('Guardar Cambios', style: TextStyle(color: Colors.white)),
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
                      content: Text('Información de "${med.nombre}" actualizada correctamente.'),
                      backgroundColor: const Color(0xFF0284C7),
                    ),
                  );
                  _loadMedications(_searchCtrl.text.trim());
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Error al actualizar la información del medicamento.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _reimportCenabast() async {
    setState(() => _isSearching = true);
    final res = await ApiService.importCenabast();
    setState(() => _isSearching = false);
    if (!mounted) return;

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
    if (!_isLoggedIn) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Color(0xFFE0F2FE),
                      child: Icon(Icons.admin_panel_settings, size: 40, color: Color(0xFF0284C7)),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Acceso Administrador',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Gestión central del catálogo de medicamentos CENABAST',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico / Usuario',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
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
                        onPressed: _isLoading ? null : _loginAdmin,
                        icon: _isLoading
                            ? const SizedBox.shrink()
                            : const Icon(Icons.login, color: Colors.white),
                        label: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Iniciar Sesión Administrador', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

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
                    onPressed: () => setState(() => _isLoggedIn = false),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF0284C7)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (val) => _loadMedications(val),
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nombre de medicamento (mínimo 2 letras)...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (val) => _loadMedications(val.trim()),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                    onPressed: () => _loadMedications(_searchCtrl.text.trim()),
                    child: const Text('Buscar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resultados del Catálogo (${_medications.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_isSearching) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 12),

          _medications.isEmpty && !_isSearching
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'Ingrese al menos 2 letras (ej: "Para", "Amo", "Ibu") en el buscador para filtrar y editar medicamentos.',
                      style: TextStyle(color: Color(0xFF64748B)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _medications.length,
                  itemBuilder: (ctx, idx) {
                    final med = _medications[idx];
                    final hasDesc = med.descripcion.isNotEmpty && med.descripcion != 'Información del medicamento';
                    final hasEfectos = med.efectosSecundarios.isNotEmpty && med.efectosSecundarios != 'No registrados';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    med.nombre,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (hasDesc || hasEfectos) ? const Color(0xFFE0F2FE) : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    (hasDesc || hasEfectos) ? 'Personalizado' : 'Sin editar',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: (hasDesc || hasEfectos) ? const Color(0xFF0284C7) : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('ID: ${med.idMedicamento}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            const SizedBox(height: 8),
                            const Text('📖 Descripción:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              hasDesc ? med.descripcion : 'Sin descripción personalizada',
                              style: TextStyle(fontSize: 13, color: hasDesc ? Colors.black87 : Colors.grey),
                            ),
                            const SizedBox(height: 6),
                            const Text('⚠️ Efectos Secundarios:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber)),
                            Text(
                              hasEfectos ? med.efectosSecundarios : 'Sin efectos secundarios personalizados',
                              style: TextStyle(fontSize: 13, color: hasEfectos ? Colors.black87 : Colors.grey),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0284C7),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                ),
                                icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                                label: const Text('Editar Información', style: TextStyle(color: Colors.white)),
                                onPressed: () => _showEditDialog(med),
                              ),
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
