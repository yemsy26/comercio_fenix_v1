import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product.dart';
import '../models/client.dart';
import '../models/invoice.dart';
import '../models/payment.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadFile(File file, String fileName) async {
    try {
      Reference ref = _storage.ref().child('products/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadURL = await snapshot.ref.getDownloadURL();
      print("Archivo subido: $downloadURL");
      return downloadURL;
    } catch (e) {
      print("Error subiendo archivo: $e");
      return null;
    }
  }

  // === Productos ===
  Future<void> addProduct(Product product) async {
    try {
      await _db.collection('products').doc(product.id).set(product.toMap());
      print("Producto agregado: ${product.id}");
    } catch (e) {
      print("Error al agregar producto: $e");
    }
  }

  Stream<List<Product>> getProducts() {
    return _db.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> updateProduct(Product product) async {
    try {
      await _db.collection('products').doc(product.id).update(product.toMap());
      print("Producto actualizado: ${product.id}");
    } catch (e) {
      print("Error al actualizar producto: $e");
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      await _db.collection('products').doc(productId).delete();
      print("Producto eliminado: $productId");
    } catch (e) {
      print("Error al eliminar producto: $e");
    }
  }

  // === Clientes ===
  Future<void> addClient(Client client) async {
    try {
      await _db.collection('clients').doc(client.id).set(client.toMap());
      print("Cliente agregado: ${client.id}");
    } catch (e) {
      print("Error al agregar cliente: $e");
    }
  }

  Stream<List<Client>> getClients() {
    return _db.collection('clients').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Client.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> updateClient(Client client) async {
    try {
      await _db.collection('clients').doc(client.id).update(client.toMap());
      print("Cliente actualizado: ${client.id}");
    } catch (e) {
      print("Error al actualizar cliente: $e");
    }
  }

  Future<void> deleteClient(String clientId) async {
    try {
      await _db.collection('clients').doc(clientId).delete();
      print("Cliente eliminado: $clientId");
    } catch (e) {
      print("Error al eliminar cliente: $e");
    }
  }

  // === Facturas ===
  Future<void> addInvoice(Invoice invoice) async {
    try {
      await _db.collection('invoices').doc(invoice.id).set(invoice.toMap());
      print("Factura agregada: ${invoice.id}");
    } catch (e) {
      print("Error al agregar factura: $e");
    }
  }

  Stream<List<Invoice>> getInvoices() {
    return _db.collection('invoices').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Invoice.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> updateInvoice(Invoice invoice) async {
    try {
      await _db.collection('invoices').doc(invoice.id).update(invoice.toMap());
      print("Factura actualizada: ${invoice.id}");
    } catch (e) {
      print("Error al actualizar factura: $e");
    }
  }

  Future<void> deleteInvoice(String invoiceId) async {
    try {
      await _db.collection('invoices').doc(invoiceId).delete();
      print("Factura eliminada: $invoiceId");
    } catch (e) {
      print("Error al eliminar factura: $e");
    }
  }

  // === Pagos ===
  Future<void> addPayment(Payment payment) async {
    try {
      await _db.collection('payments').doc(payment.id).set(payment.toMap());
      print("Pago agregado: ${payment.id}");
    } catch (e) {
      print("Error al agregar pago: $e");
    }
  }

  Stream<List<Payment>> getPayments() {
    return _db.collection('payments').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Payment.fromMap(doc.data(), doc.id)).toList();
    });
  }
}
