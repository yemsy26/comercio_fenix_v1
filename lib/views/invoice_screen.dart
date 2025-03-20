import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw; // Usamos pdf/widgets
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart' as sp;
import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/invoice.dart';
import '../models/product.dart';
import '../models/client.dart';
import '../services/database_service.dart';
import '../services/activity_log_service.dart'; // Importa el servicio de registro

// Función para llamar a la Cloud Function y reducir el stock
Future<void> reduceProductStock(String productId, int quantity) async {
  // URL de tu Cloud Function (asegúrate de que sea la correcta).
  final url = 'https://us-central1-comercio-fenix-056-14e87.cloudfunctions.net/reduceProductStock';

  // Obtén el ID token del usuario actual.
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception("No hay usuario autenticado");
  }
  final idToken = await user.getIdToken();

  // Realiza la solicitud POST incluyendo el token en el encabezado.
  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $idToken',
    },
    body: jsonEncode({
      'productId': productId,
      'quantity': quantity,
    }),
  );

  if (response.statusCode == 200) {
    print('Stock actualizado correctamente para el producto $productId');
  } else {
    throw Exception('Error al actualizar el stock: ${response.body}');
  }
}

/// =======================
/// 1) Pantalla principal: Lista de Facturas
/// =======================
class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  _InvoiceScreenState createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDate;

  List<Invoice> _filterInvoices(List<Invoice> invoices) {
    if (_selectedDate == null && _searchController.text.isEmpty) {
      invoices.sort((a, b) => b.date.compareTo(a.date));
      final todayStr = DateFormat.yMd().format(DateTime.now());
      return invoices.where((inv) => DateFormat.yMd().format(inv.date) == todayStr).toList();
    }
    return invoices.where((invoice) {
      final matchesDate = _selectedDate == null ||
          (invoice.date.year == _selectedDate!.year &&
              invoice.date.month == _selectedDate!.month &&
              invoice.date.day == _selectedDate!.day);
      final matchesSearch = _searchController.text.isEmpty ||
          invoice.clientId.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          invoice.id.contains(_searchController.text);
      return matchesDate && matchesSearch;
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Facturas"),
        backgroundColor: Colors.red.shade700,
      ),
      body: Column(
        children: [
          // Búsqueda y filtro por fecha
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Buscar por cliente o ID",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _selectedDate = null),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Invoice>>(
              stream: _dbService.getInvoices(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final invoices = _filterInvoices(snapshot.data!);
                invoices.sort((a, b) => b.date.compareTo(a.date));
                if (invoices.isEmpty) return const Center(child: Text("No se encontraron facturas"));
                return ListView.builder(
                  itemCount: invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = invoices[index];
                    final invNumber = invoice.invoiceNumber ?? invoice.id;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text("Factura #$invNumber"),
                        subtitle: Text("Cliente: ${invoice.clientId}\nFecha: ${DateFormat.yMd().format(invoice.date)}"),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => InvoiceFormScreen(invoice: invoice)),
                              );
                              ActivityLogService().record("Factura editada: ${invoice.invoiceNumber ?? invoice.id}");
                            } else if (value == 'delete') {
                              await _dbService.deleteInvoice(invoice.id);
                              ActivityLogService().record("Factura eliminada: ${invoice.invoiceNumber ?? invoice.id}");
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Factura eliminada")),
                                );
                              }
                            } else if (value == 'send') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => InvoiceDetailScreen(invoice: invoice, send: true)),
                              );
                              ActivityLogService().record("Factura enviada: ${invoice.invoiceNumber ?? invoice.id}");
                            } else if (value == 'print') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => InvoiceDetailScreen(invoice: invoice)),
                              );
                              ActivityLogService().record("Factura impresa: ${invoice.invoiceNumber ?? invoice.id}");
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text("Editar")),
                            PopupMenuItem(value: 'delete', child: Text("Eliminar")),
                            PopupMenuItem(value: 'send', child: Text("Enviar")),
                            PopupMenuItem(value: 'print', child: Text("Imprimir")),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => InvoiceDetailScreen(invoice: invoice)),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red.shade700,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InvoiceFormScreen()),
          ).then((_) {
            ActivityLogService().record("Factura creada");
          });
        },
      ),
    );
  }
}

/// =======================
/// 2) Pantalla para Crear/Editar Factura
/// =======================
class InvoiceFormScreen extends StatefulWidget {
  final Invoice? invoice;
  const InvoiceFormScreen({super.key, this.invoice});

  @override
  _InvoiceFormScreenState createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final DatabaseService _dbService = DatabaseService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: "0");
  final TextEditingController _paymentController = TextEditingController(text: "0");

  final List<InvoiceItem> _selectedItems = [];
  String _selectedPaymentMethod = "Efectivo";
  final List<String> _paymentMethods = ["Efectivo", "Transferencia", "Otro"];

  final DateTime _invoiceDate = DateTime.now();

  // Datos del negocio
  final String _businessName = "Comercio Fenix";
  final String _businessAddress = "Av. Libertad No.2";
  final String _businessPhone = "829-649-6532";
  final String? _businessLogoUrl = null;

  @override
  void initState() {
    super.initState();
    if (widget.invoice != null) {
      _clientController.text = widget.invoice!.clientId;
      _selectedPaymentMethod = widget.invoice!.paymentMethod;
      _discountController.text = widget.invoice!.discount.toString();
      _selectedItems.addAll(widget.invoice!.products);
    }
  }

  @override
  void dispose() {
    _clientController.dispose();
    _discountController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  /// ========== Diálogo Búsqueda Cliente ==========
  Future<Client?> _showClientSearchDialog(List<Client> clients) async {
    String searchTerm = "";
    return showDialog<Client>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            final filtered = clients.where((c) => c.name.toLowerCase().contains(searchTerm.toLowerCase())).toList();
            return AlertDialog(
              title: const Text("Buscar Cliente"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: "Buscar por nombre"),
                      onChanged: (value) => setStateSB(() => searchTerm = value),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final client = filtered[index];
                          return ListTile(
                            title: Text(client.name),
                            subtitle: Text(client.phone),
                            onTap: () => Navigator.pop(ctx, client),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("Crear Cliente Nuevo")),
                TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("Cancelar")),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectClient() async {
    final clients = await _dbService.getClients().first;
    final selectedClient = await _showClientSearchDialog(clients);
    if (!mounted) return;
    if (selectedClient == null) {
      final newClient = await _createNewClient();
      if (newClient != null) {
        setState(() => _clientController.text = newClient.name);
      }
    } else {
      setState(() => _clientController.text = selectedClient.name);
    }
  }

  Future<Client?> _createNewClient() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    return showDialog<Client>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Nuevo Cliente"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nombre")),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Teléfono")),
                TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: "Dirección")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("Cancelar")),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final phone = phoneCtrl.text.trim();
                final address = addressCtrl.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El nombre es obligatorio")));
                  return;
                }
                final newClient = Client(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  email: email,
                  phone: phone,
                  credit: 0,
                  address: address,
                  createdAt: DateTime.now(),
                  ownerEmail: FirebaseAuth.instance.currentUser?.email ?? '',
                );
                await _dbService.addClient(newClient);
                ActivityLogService().record("Cliente agregado: ${newClient.name}");
                Navigator.pop(ctx, newClient);
              },
              child: const Text("Crear"),
            ),
          ],
        );
      },
    );
  }

  /// ========== Diálogo Búsqueda Producto ==========
  Future<Product?> _showProductSearchDialog(List<Product> products) async {
    String searchTerm = "";
    return showDialog<Product>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            final filtered = products.where((p) => p.name.toLowerCase().contains(searchTerm.toLowerCase())).toList();
            return AlertDialog(
              title: const Text("Buscar Producto"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: "Buscar por nombre"),
                      onChanged: (value) => setStateSB(() => searchTerm = value),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return ListTile(
                            leading: product.imageUrl != null
                                ? Image.network(product.imageUrl!, width: 40, height: 40, fit: BoxFit.cover)
                                : const Icon(Icons.image_not_supported),
                            title: Text(product.name),
                            subtitle: Text("\$${product.price.toStringAsFixed(2)}"),
                            onTap: () => Navigator.pop(ctx, product),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("Crear Producto Nuevo")),
                TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("Cancelar")),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectProduct() async {
    final products = await _dbService.getProducts().first;
    final selectedProduct = await _showProductSearchDialog(products);
    if (!mounted) return;
    if (selectedProduct == null) {
      final newProd = await _createNewProduct();
      if (newProd == null) return;
      await _selectQuantityForProduct(newProd);
    } else {
      await _selectQuantityForProduct(selectedProduct);
    }
  }

  Future<Product?> _createNewProduct() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();

    return showDialog<Product>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Nuevo Producto"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nombre")),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Descripción")),
                TextField(
                  controller: priceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "Precio"),
                ),
                TextField(
                  controller: stockCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Stock"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("Cancelar")),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final desc = descCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text) ?? 0;
                final stock = int.tryParse(stockCtrl.text) ?? 0;
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El nombre es obligatorio")));
                  return;
                }
                final newProd = Product(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  description: desc,
                  price: price,
                  stock: stock,
                  imageUrl: null,
                  ownerEmail: FirebaseAuth.instance.currentUser?.email ?? '',
                );
                await _dbService.addProduct(newProd);
                ActivityLogService().record("Producto agregado: ${newProd.name}");
                Navigator.pop(ctx, newProd);
              },
              child: const Text("Crear"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectQuantityForProduct(Product product) async {
    final qtyCtrl = TextEditingController(text: "1");
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Cantidad para ${product.name}"),
          content: TextField(
            controller: qtyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Ingrese la cantidad"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text("Cancelar")),
            TextButton(
              onPressed: () {
                final qty = int.tryParse(qtyCtrl.text) ?? 1;
                Navigator.pop(ctx, qty);
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
    if (!mounted || result == null) return;
    setState(() {
      _selectedItems.add(InvoiceItem(product: product, quantity: result));
    });
  }

  /// Guardar factura y reducir stock usando la Cloud Function
  Future<void> _saveInvoice() async {
    if (_formKey.currentState?.validate() != true) return;
    final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';
    final invoiceId = widget.invoice?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final discountValue = double.tryParse(_discountController.text) ?? 0;

    final newInvoice = Invoice(
      id: invoiceId,
      clientId: _clientController.text.trim(),
      paymentMethod: _selectedPaymentMethod,
      products: _selectedItems,
      tax: 0,
      discount: discountValue,
      date: _invoiceDate,
      ownerEmail: userEmail,
      invoiceNumber: invoiceId,
      businessName: _businessName,
      businessLogoUrl: _businessLogoUrl,
      businessInfo: "$_businessAddress, Tel: $_businessPhone",
      clientSignatureUrl: null,
      vendorSignatureUrl: null,
    );

    try {
      if (widget.invoice == null) {
        await _dbService.addInvoice(newInvoice);
        ActivityLogService().record("Factura creada: ${newInvoice.invoiceNumber}");
      } else {
        await _dbService.updateInvoice(newInvoice);
        ActivityLogService().record("Factura actualizada: ${newInvoice.invoiceNumber}");
      }

      // Reducir stock utilizando la Cloud Function
      for (final item in _selectedItems) {
        try {
          await reduceProductStock(item.product.id, item.quantity);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error al actualizar stock para ${item.product.name}: $e")),
          );
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Factura guardada exitosamente")));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar factura: $e")),
      );
    }
  }

  // Funciones privadas para cálculo
  double _calcSubTotal() {
    double sum = 0;
    for (final item in _selectedItems) {
      sum += item.product.price * item.quantity;
    }
    return sum;
  }

  double _calcTotal() {
    final discount = double.tryParse(_discountController.text) ?? 0;
    return _calcSubTotal() - discount;
  }

  double _calcCambio() {
    final payment = double.tryParse(_paymentController.text) ?? 0;
    return payment - _calcTotal();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.invoice != null;
    final dateString = DateFormat('dd/MM/yyyy hh:mm a').format(_invoiceDate);

    final double subTotal = _calcSubTotal();
    final double total = _calcTotal();
    final double cambio = _calcCambio();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? "Editar Factura" : "Crear Factura"),
        backgroundColor: Colors.red.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search),
            tooltip: "Seleccionar Cliente",
            onPressed: _selectClient,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Encabezado de negocio
              Row(
                children: [
                  if (_businessLogoUrl != null)
                    Image.network(
                      _businessLogoUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, _, __) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.store),
                    ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_businessName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(_businessAddress),
                      Text("Tel: $_businessPhone"),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),
              // Fecha y hora
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Fecha y hora:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(dateString),
                ],
              ),
              const SizedBox(height: 12),
              // Cliente
              TextFormField(
                controller: _clientController,
                decoration: const InputDecoration(
                  labelText: "Cliente",
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Ingrese el cliente' : null,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _selectClient,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                child: const Text("Seleccionar/Crear Cliente"),
              ),
              const SizedBox(height: 12),
              // Método de Pago
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: "Método de Pago",
                  prefixIcon: Icon(Icons.payment),
                  border: OutlineInputBorder(),
                ),
                items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedPaymentMethod = value);
                },
              ),
              const SizedBox(height: 12),
              // Agregar Producto
              ElevatedButton.icon(
                onPressed: _selectProduct,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text("Agregar Producto"),
              ),
              const SizedBox(height: 12),
              // Lista de productos
              _selectedItems.isNotEmpty
                  ? Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: _selectedItems.map((item) {
                    final subtotalItem = item.product.price * item.quantity;
                    return ListTile(
                      leading: const Icon(Icons.inventory),
                      title: Text("${item.product.name} (\$${item.product.price.toStringAsFixed(2)})"),
                      subtitle: Text("Cantidad: ${item.quantity}  Subtotal: \$${subtotalItem.toStringAsFixed(2)}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => setState(() => _selectedItems.remove(item)),
                      ),
                    );
                  }).toList(),
                ),
              )
                  : Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text("No hay productos agregados"),
              ),
              const SizedBox(height: 12),
              // Descuento
              TextFormField(
                controller: _discountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Descuento",
                  prefixIcon: Icon(Icons.percent),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Pago
              TextFormField(
                controller: _paymentController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Pago",
                  prefixIcon: Icon(Icons.payments),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 12),
              // Resumen Totales
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Subtotal:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("\$${subTotal.toStringAsFixed(2)}"),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Descuento
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Descuento:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text("- \$${(double.tryParse(_discountController.text) ?? 0).toStringAsFixed(2)}"),
                        ],
                      ),
                      const Divider(),
                      // Total
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text("\$${total.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Cambio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Cambio:", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            "\$${cambio.toStringAsFixed(2)}",
                            style: TextStyle(color: cambio >= 0 ? Colors.green : Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saveInvoice,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                icon: const Icon(Icons.save),
                label: Text(
                  widget.invoice == null ? "Crear Factura" : "Guardar Cambios",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =======================
/// 3) Pantalla de Detalle: Imprimir/Compartir Factura
/// =======================
class InvoiceDetailScreen extends StatefulWidget {
  final Invoice invoice;
  final bool send;
  const InvoiceDetailScreen({super.key, required this.invoice, this.send = false});

  @override
  _InvoiceDetailScreenState createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  Future<Uint8List> _fetchImageBytes(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
    } catch (_) {}
    // Fallback local
    final data = await rootBundle.load('assets/logo.png');
    return data.buffer.asUint8List();
  }

  Future<Uint8List> _buildPdfDocument() async {
    final doc = pw.Document();
    Uint8List? logoBytes;

    if (widget.invoice.businessLogoUrl != null && widget.invoice.businessLogoUrl!.isNotEmpty) {
      logoBytes = await _fetchImageBytes(widget.invoice.businessLogoUrl!);
    } else {
      final data = await rootBundle.load('assets/logo.png');
      logoBytes = data.buffer.asUint8List();
    }

    final vendedor = FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email ??
        "Vendedor";

    doc.addPage(
      pw.Page(
        build: (pw.Context context) {
          final factura = widget.invoice;
          final total = factura.products.fold<double>(0, (prev, it) => prev + it.product.price * it.quantity)
              - factura.discount;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              pw.Row(
                children: [
                  if (logoBytes != null && logoBytes.isNotEmpty)
                    pw.Image(pw.MemoryImage(logoBytes), width: 80, height: 80),
                  pw.SizedBox(width: 16),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(factura.businessName ?? '',
                          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                      pw.Text(factura.businessInfo ?? ''),
                    ],
                  ),
                ],
              ),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text("Factura #: ${factura.invoiceNumber}",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text("Fecha: ${DateFormat('dd/MM/yyyy hh:mm a').format(factura.date)}"),
              pw.SizedBox(height: 8),
              pw.Text("Cliente: ${factura.clientId}"),
              pw.Text("Método de Pago: ${factura.paymentMethod}"),
              pw.Text("Descuento: \$${factura.discount.toStringAsFixed(2)}"),
              pw.Divider(),
              pw.Text("Productos:", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.ListView.builder(
                itemCount: factura.products.length,
                itemBuilder: (context, index) {
                  final item = factura.products[index];
                  final subtotal = item.product.price * item.quantity;
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("${item.product.name} x${item.quantity}"),
                      pw.Text("\$${subtotal.toStringAsFixed(2)}"),
                    ],
                  );
                },
              ),
              pw.Divider(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "Total: \$${total.toStringAsFixed(2)}",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Spacer(),
              // Pie de página
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Vendedor: $vendedor", style: pw.TextStyle(fontSize: 14)),
                  pw.Text("Cliente: ${factura.clientId}", style: pw.TextStyle(fontSize: 14)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  Future<void> _shareInvoice() async {
    final pdfData = await _buildPdfDocument();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/invoice.pdf');
    await file.writeAsBytes(pdfData);
    final xFile = XFile(file.path);
    await sp.Share.shareXFiles([xFile], text: 'Factura #${widget.invoice.invoiceNumber}');
  }

  Future<void> _printInvoice() async {
    final pdfData = await _buildPdfDocument();
    await Printing.layoutPdf(onLayout: (format) async => pdfData);
  }

  @override
  Widget build(BuildContext context) {
    final factura = widget.invoice;
    final invNumber = factura.invoiceNumber ?? factura.id;
    return Scaffold(
      appBar: AppBar(
        title: Text("Factura #$invNumber"),
        backgroundColor: Colors.red.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareInvoice,
            tooltip: "Enviar Factura",
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printInvoice,
            tooltip: "Imprimir Factura",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Row(
              children: [
                if (factura.businessLogoUrl != null && factura.businessLogoUrl!.isNotEmpty)
                  Image.network(
                    factura.businessLogoUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  )
                else
                  const SizedBox(width: 80, height: 80),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(factura.businessName ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(factura.businessInfo ?? ''),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),
            Text("Factura #: $invNumber", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Fecha: ${DateFormat('dd/MM/yyyy hh:mm a').format(factura.date)}"),
            const SizedBox(height: 16),
            Text("Cliente: ${factura.clientId}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text("Método de Pago: ${factura.paymentMethod}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text("Descuento: \$${factura.discount.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16)),
            const Divider(height: 32),
            const Text("Productos:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: factura.products.length,
              itemBuilder: (context, index) {
                final item = factura.products[index];
                final subtotal = item.product.price * item.quantity;
                return ListTile(
                  title: Text(item.product.name),
                  subtitle: Text("Cantidad: ${item.quantity} - \$${subtotal.toStringAsFixed(2)}"),
                );
              },
            ),
            const Divider(height: 32),
            Text(
              "Total: \$${(factura.products.fold<double>(0, (prev, it) => prev + it.product.price * it.quantity) - factura.discount).toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Pie de página
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Vendedor: ${FirebaseAuth.instance.currentUser?.displayName ?? FirebaseAuth.instance.currentUser?.email ?? 'Vendedor'}",
                    style: const TextStyle(fontSize: 14)),
                Text("Cliente: ${factura.clientId}", style: const TextStyle(fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
