import 'package:hive/hive.dart';
import '../models/invoice.dart';

class LocalDatabaseService {
  static const String invoiceBoxName = 'invoices';
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  Future<void> init() async {
    await Hive.openBox(invoiceBoxName);
  }

  Future<void> addInvoiceLocal(Invoice invoice) async {
    var box = Hive.box(invoiceBoxName);
    Map<String, dynamic> invoiceMap = invoice.toMap();
    invoiceMap['id'] = invoice.id;
    await box.put(invoice.id, invoiceMap);
  }

  // Métodos similares para update y delete si deseas

  List<Invoice> getInvoicesLocal() {
    var box = Hive.box(invoiceBoxName);
    return box.values.map((data) {
      final Map<String, dynamic> invoiceData = Map<String, dynamic>.from(data);
      final String id = invoiceData['id'] ?? '';
      return Invoice.fromMap(invoiceData, id);
    }).toList();
  }


  Future<void> syncInvoices() async {
    try {
      // Lógica de sincronización:
      // 1. Leer facturas locales
      // 2. Enviarlas o actualizarlas en Firestore
      // 3. Manejar conflictos o reintentos si es necesario
      print("Sincronizando facturas locales con Firestore...");
    } catch (e) {
      print("Error al sincronizar facturas: $e");
    }
  }

}
