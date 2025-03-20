class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String? imageUrl;
  final String ownerEmail;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.ownerEmail,
  });

  factory Product.fromMap(Map<String, dynamic> data, String documentId) {
    return Product(
      id: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      stock: data['stock'] as int? ?? 0,
      imageUrl: data['imageUrl'] as String?,
      ownerEmail: data['ownerEmail'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'ownerEmail': ownerEmail,
    };
  }
}
