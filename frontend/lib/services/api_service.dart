import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5001/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5001/api';
    }
    return 'http://127.0.0.1:5001/api';
  }

  // Check Backend Health
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/../health')).timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Register Prescription (Supports multiple medications per prescription)
  static Future<Map<String, dynamic>> registerPrescription({
    required List<Map<String, dynamic>> medications,
    String metodoIngreso = 'Manual',
    String pacienteId = 'demo',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/prescriptions/manual'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'IdPaciente': pacienteId,
        'MetodoIngreso': metodoIngreso,
        'Medications': medications,
      }),
    );

    return jsonDecode(response.body);
  }

  // Legacy helper method for single medication registration
  static Future<Map<String, dynamic>> registerManualPrescription({
    required String nombre,
    required int frecuenciaHoras,
    required int duracionDias,
    required String horaInicio,
  }) async {
    return registerPrescription(
      medications: [
        {
          'Nombre': nombre,
          'FrecuenciaHoras': frecuenciaHoras,
          'DuracionDias': duracionDias,
          'HoraInicio': horaInicio,
        }
      ],
      metodoIngreso: 'Manual',
    );
  }


  // Fetch Patient Calendar
  static Future<List<ItemCalendarioModel>> getCalendar({String pacienteId = 'demo'}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/calendar/$pacienteId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List itemsJson = data['calendario']['Items'] ?? [];
        return itemsJson.map((i) => ItemCalendarioModel.fromJson(i)).toList();
      }
    } catch (e) {
      debugPrint('Error loading calendar: $e');
    }
    return [];
  }

  // Modify Schedule
  static Future<bool> modifySchedule(String pacienteId, String itemId, String newTime) async {
    final response = await http.put(
      Uri.parse('$baseUrl/calendar/$pacienteId/items/$itemId/horario'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Hora': newTime}),
    );
    return response.statusCode == 200;
  }

  // Modify Frequency
  static Future<bool> modifyFrequency(String pacienteId, String itemId, int newFrequency) async {
    final response = await http.put(
      Uri.parse('$baseUrl/calendar/$pacienteId/items/$itemId/frecuencia'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Frecuencia': newFrequency}),
    );
    return response.statusCode == 200;
  }

  // Modify Duration
  static Future<bool> modifyDuration(String pacienteId, String itemId, int newDuration) async {
    final response = await http.put(
      Uri.parse('$baseUrl/calendar/$pacienteId/items/$itemId/duracion'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'Duracion': newDuration}),
    );
    return response.statusCode == 200;
  }

  // Delete Calendar Item
  static Future<bool> deleteItem(String pacienteId, String itemId) async {
    final response = await http.delete(Uri.parse('$baseUrl/calendar/$pacienteId/items/$itemId'));
    return response.statusCode == 200;
  }

  // Fetch Medications Catalogue
  static Future<List<MedicamentoModel>> getMedications({String query = ''}) async {
    try {
      final uri = Uri.parse('$baseUrl/medications').replace(queryParameters: query.isNotEmpty ? {'q': query} : null);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['medicamentos'] ?? [];
        return list.map((m) => MedicamentoModel.fromJson(m)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching medications: $e');
    }
    return [];
  }

  // Add Note
  static Future<bool> addNote({required String pacienteId, String? medicamentoId, required String descripcion}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'IdPaciente': pacienteId,
        'IdMedicamento': medicamentoId,
        'Descripcion': descripcion,
      }),
    );
    return response.statusCode == 201;
  }

  // Fetch Notes
  static Future<List<NotaModel>> getNotes(String pacienteId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notes/$pacienteId'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['notas'] ?? [];
        return list.map((n) => NotaModel.fromJson(n)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching notes: $e');
    }
    return [];
  }

  // Generate Sync Code
  static Future<String?> generateSyncCode(String pacienteId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sync/generate-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'IdPaciente': pacienteId}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['Codigo'];
      }
    } catch (e) {
      debugPrint('Error generating code: $e');
    }
    return null;
  }

  // Link Caregiver
  static Future<Map<String, dynamic>> linkSyncCode(String code) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sync/link'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'CodigoSincronizacion': code}),
    );
    return jsonDecode(response.body);
  }

  // Scan Prescription Photo with optional crop box (Privacy PII Protection)
  static Future<Map<String, dynamic>> scanPrescriptionImage({
    required List<int> bytes,
    required String filename,
    Map<String, double>? cropBox,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/prescriptions/scan'));
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    if (cropBox != null) {
      request.fields['crop_box'] = jsonEncode(cropBox);
    }
    final streamedRes = await request.send();
    final response = await http.Response.fromStream(streamedRes);
    return jsonDecode(response.body);
  }

  // Read Prescription PDF
  static Future<Map<String, dynamic>> readPrescriptionPdf({
    required List<int> bytes,
    required String filename,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/prescriptions/pdf'));
    request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamedRes = await request.send();
    final response = await http.Response.fromStream(streamedRes);
    return jsonDecode(response.body);
  }
}

