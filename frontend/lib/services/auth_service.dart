import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String googleWebClientId = '302408538755-4k06v1eur6dqjes98eqfvce04drc8e27.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? googleWebClientId : null,
    serverClientId: kIsWeb ? null : googleWebClientId,
    scopes: ['email', 'profile'],
  );

  static final ValueNotifier<UsuarioModel?> currentUserNotifier = ValueNotifier<UsuarioModel?>(null);
  static final ValueNotifier<PacienteModel?> currentPacienteNotifier = ValueNotifier<PacienteModel?>(null);
  static final ValueNotifier<String?> linkedPatientIdNotifier = ValueNotifier<String?>(null);
  static final ValueNotifier<String?> linkedPatientNameNotifier = ValueNotifier<String?>(null);

  static UsuarioModel? get currentUser => currentUserNotifier.value;
  static PacienteModel? get currentPaciente => currentPacienteNotifier.value;
  static bool get isAuthenticated => currentUserNotifier.value != null;

  static bool get isCaregiver => currentUser?.rol == 'cuidador';
  static bool get isPatient => currentUser?.rol == 'paciente';
  static bool get isAdmin => currentUser?.rol == 'administrador';

  static String get currentPacienteId {
    if (isCaregiver) {
      return linkedPatientIdNotifier.value ?? '';
    }
    if (isAuthenticated) {
      return currentPacienteNotifier.value?.idPaciente ?? '';
    }
    return 'demo';
  }

  /// Sign in using Google Account
  static Future<Map<String, dynamic>> signInWithGoogle({String role = 'paciente'}) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'status': 'cancelled', 'message': 'Inicio de sesión cancelado'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      final res = await _syncWithBackend(
        email: googleUser.email,
        name: googleUser.displayName ?? 'Usuario Google',
        role: role,
        idToken: idToken,
        photoUrl: googleUser.photoUrl,
      );

      return res;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return {'status': 'error', 'message': 'Error al iniciar sesión con Google: $e'};
    }
  }

  /// Admin login with email & password
  static Future<Map<String, dynamic>> loginAdmin({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || cleanPass.isEmpty) {
      return {'status': 'error', 'message': 'Ingrese correo y contraseña'};
    }

    return await _syncWithBackend(
      email: cleanEmail,
      name: 'Administrador CENABAST',
      role: 'administrador',
    );
  }

  /// Switch active role between 'paciente' and 'cuidador'
  static Future<Map<String, dynamic>> switchRole(String newRole) async {
    final user = currentUser;
    if (user == null) {
      return {'status': 'error', 'message': 'No hay sesión activa'};
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/switch-role'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_usuario': user.idUsuario,
          'email': user.correo,
          'role': newRole,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        final updatedUser = UsuarioModel.fromJson(data['usuario'], photoUrl: user.photoUrl);
        currentUserNotifier.value = updatedUser;

        if (data['paciente'] != null) {
          currentPacienteNotifier.value = PacienteModel.fromJson(data['paciente']);
        }

        return {'status': 'success', 'user': updatedUser};
      } else {
        return {'status': 'error', 'message': data['error'] ?? 'Error al cambiar rol'};
      }
    } catch (e) {
      debugPrint('Switch Role Error: $e');
      return {'status': 'error', 'message': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> _syncWithBackend({
    required String email,
    required String name,
    required String role,
    String? idToken,
    String? photoUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'role': role,
          'id_token': idToken,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        final user = UsuarioModel.fromJson(data['usuario'], photoUrl: photoUrl);
        currentUserNotifier.value = user;

        if (data['paciente'] != null) {
          currentPacienteNotifier.value = PacienteModel.fromJson(data['paciente']);
        } else {
          currentPacienteNotifier.value = null;
        }

        return {'status': 'success', 'user': user};
      } else {
        return {'status': 'error', 'message': data['error'] ?? 'Error de autenticación en el servidor'};
      }
    } catch (e) {
      debugPrint('Backend Auth Sync Error: $e');
      return {'status': 'error', 'message': 'No se pudo conectar con el servidor de autenticación: $e'};
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    currentUserNotifier.value = null;
    currentPacienteNotifier.value = null;
    linkedPatientIdNotifier.value = null;
    linkedPatientNameNotifier.value = null;
  }
}
