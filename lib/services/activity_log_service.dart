import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Clase que representa una entrada del historial.
class ActivityLogEntry {
  final DateTime timestamp;
  final String user;
  final String message;

  ActivityLogEntry({
    required this.timestamp,
    required this.user,
    required this.message,
  });

  String get formatted =>
      "${DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp)} - $user: $message";
}

/// Servicio global para registrar las actividades del usuario.
class ActivityLogService {
  static final ActivityLogService _instance = ActivityLogService._internal();
  factory ActivityLogService() => _instance;
  ActivityLogService._internal();

  final List<ActivityLogEntry> _activityLog = [];

  /// Registra un mensaje junto con el usuario actual.
  void record(String message, {String? user}) {
    final now = DateTime.now();
    final currentUser = user ??
        FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email ??
        "Usuario desconocido";
    _activityLog.add(ActivityLogEntry(timestamp: now, user: currentUser, message: message));
  }

  /// Retorna la lista completa de actividades.
  List<ActivityLogEntry> get log => _activityLog;
}
