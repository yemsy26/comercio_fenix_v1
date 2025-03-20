import 'local_database_service.dart';
import 'database_service.dart';
import '../models/invoice.dart';

class ManualSyncService {
  final LocalDatabaseService _localDB = LocalDatabaseService();
  final DatabaseService _dbService = DatabaseService();

  Future<void> syncLocalDataManually() async {
    try {
      final localInvoices = _localDB.getInvoicesLocal();
      for (Invoice invoice in localInvoices) {
        await _dbService.addInvoice(invoice);
      }
      print("Sincronización manual completada");
    } catch (e) {
      print("Error en la sincronización manual: $e");
    }
  }
}
