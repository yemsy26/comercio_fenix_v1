import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'local_database_service.dart';


class SyncService {
  final LocalDatabaseService _localDB = LocalDatabaseService();
  StreamSubscription? _subscription;

  void startMonitoring() {
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      // Aquí, result es de tipo ConnectivityResult
      if (result != ConnectivityResult.none) {
        // Sincroniza cuando detecte conexión
        _localDB.syncInvoices();
        print("Conexión detectada. Sincronizando datos locales...");
      }
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
