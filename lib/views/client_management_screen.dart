import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/client.dart';
import '../services/database_service.dart';
import '../services/activity_log_service.dart'; // Asegúrate de tener este servicio

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({Key? key}) : super(key: key);

  @override
  _ClientManagementScreenState createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Controladores para el formulario (se eliminó crédito)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  void _clearClientFields() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _addressController.clear();
  }

  Future<void> _showAddEditClientDialog({Client? client}) async {
    if (client != null) {
      _nameController.text = client.name;
      _emailController.text = client.email;
      _phoneController.text = client.phone;
      _addressController.text = client.address;
    } else {
      _clearClientFields();
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(client == null ? "Agregar Cliente" : "Editar Cliente"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Nombre"),
                ),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: "Correo"),
                ),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Teléfono"),
                ),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: "Dirección"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearClientFields();
                Navigator.pop(context);
              },
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                final email = _emailController.text.trim();
                final phone = _phoneController.text.trim();
                final address = _addressController.text.trim();

                if (name.isEmpty || email.isEmpty || phone.isEmpty || address.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Complete todos los campos")),
                  );
                  return;
                }

                final userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

                if (client == null) {
                  final newClient = Client(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    email: email,
                    phone: phone,
                    credit: 0, // Se establece 0 o se ignora en la UI
                    address: address,
                    createdAt: DateTime.now(),
                    ownerEmail: userEmail,
                  );
                  await _dbService.addClient(newClient);
                  ActivityLogService().record("Cliente agregado: ${newClient.name}");
                } else {
                  final updatedClient = Client(
                    id: client.id,
                    name: name,
                    email: email,
                    phone: phone,
                    credit: client.credit, // Mantiene el valor original
                    address: address,
                    createdAt: client.createdAt,
                    ownerEmail: client.ownerEmail,
                  );
                  await _dbService.updateClient(updatedClient);
                  ActivityLogService().record("Cliente actualizado: ${updatedClient.name}");
                }
                Navigator.pop(context);
                _clearClientFields();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: Text(client == null ? "Agregar" : "Guardar Cambios"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteClient(String clientId, String clientName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text("¿Está seguro de eliminar este cliente?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _dbService.deleteClient(clientId);
      ActivityLogService().record("Cliente eliminado: $clientName");
    }
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        hintText: 'Buscar cliente...',
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
        icon: Icon(Icons.search, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildSearchBar(),
        backgroundColor: Colors.red.shade700,
      ),
      body: StreamBuilder<List<Client>>(
        stream: _dbService.getClients(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allClients = snapshot.data!;
          final filteredClients = allClients.where((client) {
            final query = _searchQuery;
            return client.name.toLowerCase().contains(query) ||
                client.email.toLowerCase().contains(query) ||
                client.phone.toLowerCase().contains(query);
          }).toList();

          // Aquí se organiza la lista de clientes por orden alfabético (por nombre)
          filteredClients.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          if (filteredClients.isEmpty) {
            return const Center(child: Text("No hay clientes que coincidan con la búsqueda."));
          }
          return ListView.builder(
            itemCount: filteredClients.length,
            itemBuilder: (context, index) {
              final client = filteredClients[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    client.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("${client.email}\n${client.phone}\n${client.address}"),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddEditClientDialog(client: client),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteClient(client.id, client.name),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red.shade700,
        onPressed: () => _showAddEditClientDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
