import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String method; // 'efectivo', 'transferencia', 'paypal', etc.
  final double amount;
  final DateTime date;

  Payment({
    required this.id,
    required this.method,
    required this.amount,
    required this.date,
  });

  factory Payment.fromMap(Map<String, dynamic> data, String documentId) {
    return Payment(
      id: documentId,
      method: data['method'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'amount': amount,
      'date': date,
    };
  }
}
