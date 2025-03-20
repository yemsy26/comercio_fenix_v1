import 'package:cloud_firestore/cloud_firestore.dart';
import 'product.dart';

/// Modelo para representar un ítem en la factura (producto + cantidad)
class InvoiceItem {
  final Product product;
  final int quantity;
  InvoiceItem({required this.product, required this.quantity});

  Map<String, dynamic> toMap() {
    return {
      ...product.toMap(),
      'quantity': quantity,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> data) {
    return InvoiceItem(
      product: Product.fromMap(data, data['id'] ?? ''),
      quantity: data['quantity'] ?? 1,
    );
  }
}

class Invoice {
  final String id;
  final String clientId;
  final String paymentMethod;
  final List<InvoiceItem> products; // Cambiado: usamos "products"
  final double tax;
  final double discount;
  final DateTime date;
  final String ownerEmail;

  // Campos adicionales para la factura profesional
  final String? invoiceNumber;
  final String? businessName;
  final String? businessLogoUrl;
  final String? businessInfo;
  final String? clientSignatureUrl;
  final String? vendorSignatureUrl;

  Invoice({
    required this.id,
    required this.clientId,
    required this.paymentMethod,
    required this.products,
    required this.tax,
    required this.discount,
    required this.date,
    required this.ownerEmail,
    this.invoiceNumber,
    this.businessName,
    this.businessLogoUrl,
    this.businessInfo,
    this.clientSignatureUrl,
    this.vendorSignatureUrl,
  });

  factory Invoice.fromMap(Map<String, dynamic> data, String documentId) {
    return Invoice(
      id: documentId,
      clientId: data['clientId'] ?? '',
      paymentMethod: data['paymentMethod'] ?? '',
      products: data['products'] != null
          ? List<InvoiceItem>.from(
          (data['products'] as List).map((item) => InvoiceItem.fromMap(item)))
          : [],
      tax: (data['tax'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      ownerEmail: data['ownerEmail'] ?? '',
      invoiceNumber: data['invoiceNumber'],
      businessName: data['businessName'],
      businessLogoUrl: data['businessLogoUrl'],
      businessInfo: data['businessInfo'],
      clientSignatureUrl: data['clientSignatureUrl'],
      vendorSignatureUrl: data['vendorSignatureUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'paymentMethod': paymentMethod,
      'products': products.map((item) => item.toMap()).toList(), // Guardamos en "products"
      'tax': tax,
      'discount': discount,
      'date': date,
      'ownerEmail': ownerEmail,
      'invoiceNumber': invoiceNumber,
      'businessName': businessName,
      'businessLogoUrl': businessLogoUrl,
      'businessInfo': businessInfo,
      'clientSignatureUrl': clientSignatureUrl,
      'vendorSignatureUrl': vendorSignatureUrl,
    };
  }
}
