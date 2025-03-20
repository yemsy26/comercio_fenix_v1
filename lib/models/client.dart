import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String id;
  final String name;
  final String email;
  final String phone;
  final double credit;
  final String address;
  final DateTime createdAt;
  final String ownerEmail;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.credit,
    required this.address,
    required this.createdAt,
    required this.ownerEmail,
  });

  factory Client.fromMap(Map<String, dynamic> data, String documentId) {
    return Client(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      credit: (data['credit'] as num?)?.toDouble() ?? 0.0,
      address: data['address'] ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      ownerEmail: data['ownerEmail'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'credit': credit,
      'address': address,
      'createdAt': createdAt,
      'ownerEmail': ownerEmail,
    };
  }
}

