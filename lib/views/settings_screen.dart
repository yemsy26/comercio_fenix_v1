import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/manual_sync_service.dart';
import '../services/auth_service.dart';
import '../services/activity_log_service.dart'; // Servicio de registro
import '../utils/routes.dart';
// Pantalla para ver el historial

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  bool _isSyncing = false;
  XFile? _selectedImage; // Para editar la foto de perfil

  Future<void> _syncDataManually() async {
    setState(() => _isSyncing = true);
    await ManualSyncService().syncLocalDataManually();
    if (!mounted) return;
    ActivityLogService().record("Sincronizó la base de datos");
    setState(() => _isSyncing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Base de datos actualizada")),
    );
  }

  Future<void> _clearCache() async {
    // Aquí puedes integrar la lógica real de limpiar caché
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    ActivityLogService().record("Limpiado caché");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Caché limpiada")),
    );
  }

  Future<void> _editProfile() async {
    final user = _authService.currentUser;
    final TextEditingController nameCtrl =
    TextEditingController(text: user?.displayName ?? "");
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Perfil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                final picker = ImagePicker();
                final picked = await picker.pickImage(source: ImageSource.gallery);
                if (picked != null) {
                  setState(() {
                    _selectedImage = picked;
                  });
                }
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text("Cambiar foto"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) return;
              await _authService.updateUserProfile(newName, _selectedImage);
              ActivityLogService().record("Actualizó perfil: $newName");
              Navigator.pop(context);
              setState(() {}); // Para refrescar el encabezado
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<void> _showActivityLog() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ActivityLogScreen()),
    );
  }

  Future<void> _showAbout() async {
    showAboutDialog(
      context: context,
      applicationName: "Comercio Fenix",
      applicationVersion: "v1.0.0",
      applicationIcon: Image.asset('assets/logo.png', width: 50, height: 50),
      children: const [
        Text("Primera versión local de Comercio Fenix.\nDesarrollado por [Ramon Burgos]."),
      ],
    );
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    ActivityLogService().record("Cerró sesión");
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, Routes.login);
  }

  /// Construye el encabezado del usuario con foto, nombre y correo.
  Widget _buildUserHeader() {
    final user = _authService.currentUser;
    return InkWell(
      onTap: _editProfile,
      child: Container(
        color: Colors.red.shade100,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null ? const Icon(Icons.person, size: 30) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? "Sin nombre",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? "",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, color: Colors.red),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajustes"),
        backgroundColor: Colors.red.shade700,
      ),
      body: ListView(
        children: [
          _buildUserHeader(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text("Sincronizar Base de Datos"),
            trailing: _isSyncing ? const CircularProgressIndicator() : null,
            onTap: _isSyncing ? null : _syncDataManually,
          ),
          ListTile(
            leading: const Icon(Icons.clear_all),
            title: const Text("Limpiar Caché"),
            onTap: _clearCache,
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("Historial de Actividades"),
            onTap: _showActivityLog,
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text("Acerca de"),
            onTap: _showAbout,
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Cerrar Sesión"),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}

/// Pantalla para mostrar el historial de actividades con filtrado por fecha.
class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  // Por defecto se filtra por el día actual.
  DateTime _filterDate = DateTime.now();

  List<ActivityLogEntry> get _filteredLog {
    return ActivityLogService().log.where((entry) {
      return entry.timestamp.year == _filterDate.year &&
          entry.timestamp.month == _filterDate.month &&
          entry.timestamp.day == _filterDate.day;
    }).toList();
  }

  Future<void> _selectFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _filterDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLog = _filteredLog;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Actividades"),
        backgroundColor: Colors.red.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectFilterDate,
            tooltip: "Filtrar por fecha",
          ),
        ],
      ),
      body: filteredLog.isEmpty
          ? const Center(child: Text("No hay actividades registradas para la fecha seleccionada."))
          : ListView.builder(
        itemCount: filteredLog.length,
        itemBuilder: (context, index) {
          final entry = filteredLog[index];
          return ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(entry.formatted),
          );
        },
      ),
    );
  }
}
