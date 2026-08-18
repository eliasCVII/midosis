import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/auth_service.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const AuthDialog(),
    );
  }

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  bool _isLoading = false;
  String _selectedRole = 'usuario';
  String? _errorMessage;

  final TextEditingController _adminEmailCtrl = TextEditingController();
  final TextEditingController _adminPassCtrl = TextEditingController();

  @override
  void dispose() {
    _adminEmailCtrl.dispose();
    _adminPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await AuthService.signInWithGoogle(role: 'paciente');

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['status'] == 'success') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Bienvenido(a), ${(res['user'] as UsuarioModel).nombre}!'),
          backgroundColor: const Color(0xFF0284C7),
        ),
      );
    } else if (res['status'] != 'cancelled') {
      setState(() {
        _errorMessage = res['message'] ?? 'Error al autenticar con Google';
      });
    }
  }

  Future<void> _handleAdminLogin() async {
    final email = _adminEmailCtrl.text.trim();
    final pass = _adminPassCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Ingrese correo y contraseña de administrador');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await AuthService.loginAdmin(email: email, password: pass);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['status'] == 'success') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión de Administrador iniciada exitosamente'),
          backgroundColor: Color(0xFF0284C7),
        ),
      );
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Credenciales de administrador inválidas';
      });
    }
  }

  Future<void> _handleSignOut() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada correctamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UsuarioModel?>(
      valueListenable: AuthService.currentUserNotifier,
      builder: (context, user, _) {
        if (user != null) {
          return _buildUserProfileDialog(user);
        }
        return _buildLoginDialog();
      },
    );
  }

  Widget _buildUserProfileDialog(UsuarioModel user) {
    final paciente = AuthService.currentPaciente;
    final isAdmin = user.rol == 'administrador';
    final isCuidador = user.rol == 'cuidador';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE0F2FE),
            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? Text(
                    user.nombre.isNotEmpty ? user.nombre[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  user.correo,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Modo Activo: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? Colors.amber.shade100
                        : isCuidador
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.rol.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isAdmin
                          ? Colors.brown
                          : isCuidador
                              ? const Color(0xFF059669)
                              : const Color(0xFF0284C7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (paciente != null && paciente.codigoSincronizacion != null) ...[
              const Text('Tu Código de Sincronización:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      paciente.codigoSincronizacion!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18, color: Color(0xFF0284C7)),
                      tooltip: 'Copiar código',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: paciente.codigoSincronizacion!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('¡Código copiado al portapapeles!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: _handleSignOut,
          icon: const Icon(Icons.logout, color: Colors.red),
          label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0284C7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text('Aceptar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildLoginDialog() {
    final isAdmin = _selectedRole == 'administrador';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE0F2FE),
            child: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.lock_person,
              color: const Color(0xFF0284C7),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            isAdmin ? 'Acceso Administrador' : 'Iniciar Sesión',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isAdmin
                    ? 'Ingrese sus credenciales de administrador para gestionar el catálogo central de CENABAST.'
                    : 'Inicia sesión con tu cuenta de Google. Podrás alternar entre modo Paciente y Cuidador en cualquier momento desde la barra superior.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              const Text('Tipo de acceso:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'usuario',
                    icon: Icon(Icons.people_outline, size: 16),
                    label: Text('Paciente / Cuidador'),
                  ),
                  ButtonSegment(
                    value: 'administrador',
                    icon: Icon(Icons.admin_panel_settings_outlined, size: 16),
                    label: Text('Administrador'),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (set) => setState(() {
                  _selectedRole = set.first;
                  _errorMessage = null;
                }),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (isAdmin) ...[
                TextFormField(
                  controller: _adminEmailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico / Usuario',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _adminPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoading ? null : _handleAdminLogin,
                    icon: _isLoading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.login, color: Colors.white),
                    label: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Iniciar Sesión Administrador',
                            style: TextStyle(fontSize: 15, color: Colors.white),
                          ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://fonts.gstatic.com/s/i/productlogos/googleg/v6/24px.svg',
                                width: 20,
                                height: 20,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.g_mobiledata, size: 24, color: Colors.blue),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Continuar con Google',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
