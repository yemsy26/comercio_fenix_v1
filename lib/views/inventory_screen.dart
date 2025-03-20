import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/product.dart';
import '../services/database_service.dart';
import '../services/activity_log_service.dart'; // Para registrar acciones

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final DatabaseService _dbService = DatabaseService();

  // Controladores para el formulario y búsqueda
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  File? _selectedImage;
  String _searchQuery = '';

  // Solicita permiso para acceder a la galería
  Future<bool> _requestGalleryPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  // Selecciona imagen usando image_picker
  Future<void> _pickImage() async {
    bool granted = await _requestGalleryPermission();
    if (!mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Permiso denegado para acceder a imágenes")),
      );
      return;
    }
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  // Muestra el formulario para agregar o editar producto
  Future<void> _showProductForm({Product? product}) async {
    if (product != null) {
      _nameController.text = product.name;
      _descriptionController.text = product.description;
      _priceController.text = product.price.toString();
      _stockController.text = product.stock.toString();
      _selectedImage = null; // Mantiene la imagen anterior si no se cambia
    } else {
      _nameController.clear();
      _descriptionController.clear();
      _priceController.clear();
      _stockController.clear();
      _selectedImage = null;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product == null ? "Agregar Producto" : "Editar Producto",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: "Nombre", border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese un nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                        labelText: "Descripción", border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese una descripción';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: "Precio", border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese un precio';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Ingrese un número válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: "Stock", border: OutlineInputBorder()),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ingrese la cantidad en stock';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Ingrese un número entero válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                    child: Text(_selectedImage == null ? "Seleccionar Imagen" : "Cambiar Imagen"),
                  ),
                  if (_selectedImage != null)
                    GestureDetector(
                      onTap: () => _showImagePreview(_selectedImage!),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.file(_selectedImage!, height: 80),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() != true) return;

                      final name = _nameController.text.trim();
                      final description = _descriptionController.text.trim();
                      final price = double.parse(_priceController.text);
                      final stock = int.parse(_stockController.text);

                      final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
                      final productId = product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

                      String? imageUrl;
                      if (_selectedImage != null) {
                        imageUrl = await _dbService.uploadFile(_selectedImage!, "product_$productId.jpg");
                        if (!mounted) return;
                      }

                      final newProduct = Product(
                        id: productId,
                        name: name,
                        description: description,
                        price: price,
                        stock: stock,
                        imageUrl: imageUrl ?? product?.imageUrl,
                        ownerEmail: userEmail,
                      );

                      if (product == null) {
                        await _dbService.addProduct(newProduct);
                        ActivityLogService().record("Producto agregado: ${newProduct.name}");
                      } else {
                        await _dbService.updateProduct(newProduct);
                        ActivityLogService().record("Producto actualizado: ${newProduct.name}");
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: Text(
                      product == null ? "Agregar Producto" : "Guardar Cambios",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Muestra imagen en pantalla completa (para archivo local o URL)
  Future<void> _showImagePreview(dynamic imageSource) async {
    Widget imageWidget;
    if (imageSource is File) {
      imageWidget = Image.file(imageSource);
    } else if (imageSource is String) {
      imageWidget = Image.network(imageSource);
    } else {
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(10),
            child: InteractiveViewer(child: imageWidget),
          ),
        );
      },
    );
  }

  // Opciones para editar o eliminar producto
  void _showProductOptions(Product product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("Editar"),
                onTap: () {
                  Navigator.pop(context);
                  _showProductForm(product: product);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text("Eliminar"),
                onTap: () async {
                  Navigator.pop(context);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Confirmar eliminación"),
                      content: const Text("¿Estás seguro de eliminar este producto?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancelar"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Eliminar"),
                        ),
                      ],
                    ),
                  );
                  if (!mounted) return;
                  if (confirm == true) {
                    await _dbService.deleteProduct(product.id);
                    ActivityLogService().record("Producto eliminado: ${product.name}");
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Construye la tarjeta de producto con navegación a vista de detalle
  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        leading: product.imageUrl != null
            ? GestureDetector(
          onTap: () => _showImagePreview(product.imageUrl),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              product.imageUrl!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          ),
        )
            : Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.image_not_supported, size: 30),
        ),
        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Precio: \$${product.price.toStringAsFixed(2)}\nStock: ${product.stock}"),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showProductOptions(product),
        ),
      ),
    );
  }

  // Filtro local de productos según el texto de búsqueda
  List<Product> _filterProducts(List<Product> products) {
    if (_searchQuery.isEmpty) return products;
    return products.where((product) =>
    product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        product.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Productos disponibles en Almacén"),
        backgroundColor: Colors.red.shade700,
        actions: [
          // Búsqueda mediante delegado
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(
                  allProductsStream: _dbService.getProducts(),
                  onSelected: (product) {
                    if (product == null) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Campo de búsqueda local
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Buscar productos...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _dbService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final filteredProducts = _filterProducts(snapshot.data!);
                // Se organiza la lista en orden alfabético (por nombre) sin alterar el resto de la lógica
                filteredProducts.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                if (filteredProducts.isEmpty) {
                  return const Center(child: Text("No hay productos en la base de datos"));
                }
                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(filteredProducts[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductForm(),
        backgroundColor: Colors.red.shade700,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Vista de detalle del producto
class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  // Muestra una vista previa ampliada de la imagen
  Future<void> _showImagePreview(BuildContext context, dynamic imageSource) async {
    Widget imageWidget;
    if (imageSource is File) {
      imageWidget = Image.file(imageSource);
    } else if (imageSource is String) {
      imageWidget = Image.network(imageSource);
    } else {
      return;
    }
    await showDialog(
      context: context,
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(10),
            child: InteractiveViewer(child: imageWidget),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Colors.red.shade700,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            product.imageUrl != null
                ? GestureDetector(
              onTap: () => _showImagePreview(context, product.imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  product.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            )
                : Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.image_not_supported, size: 50),
            ),
            const SizedBox(height: 20),
            Text(
              product.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              product.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Precio: \$${product.price.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  "Stock: ${product.stock}",
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Delegado de búsqueda para productos
class ProductSearchDelegate extends SearchDelegate<Product?> {
  final Stream<List<Product>> allProductsStream;
  final Function(Product?) onSelected;

  ProductSearchDelegate({
    required this.allProductsStream,
    required this.onSelected,
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isNotEmpty) {
      return [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];
    }
    return null;
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: allProductsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final results = snapshot.data!
            .where((product) =>
        product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.description.toLowerCase().contains(query.toLowerCase()))
            .toList();

        if (results.isEmpty) {
          return const Center(child: Text("No se encontraron productos"));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final product = results[index];
            return ListTile(
              leading: product.imageUrl != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              )
                  : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_not_supported),
              ),
              title: Text(product.name),
              subtitle: Text("Stock: ${product.stock}"),
              onTap: () {
                close(context, product);
                onSelected(product);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
