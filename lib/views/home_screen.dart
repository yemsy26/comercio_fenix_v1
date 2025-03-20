import 'package:flutter/material.dart';
import 'inventory_screen.dart';
import 'invoice_screen.dart';
import 'client_management_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const InventoryScreen(),
    const InvoiceScreen(),
    const ClientManagementScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  final List<String> _titles = [
    'Inventario',
    'Facturación',
    'Clientes',
    'Reportes',
    'Ajustes',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.red[700],
        elevation: 4,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[700]!, Colors.red[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.red[700],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Inventario'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Facturación'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}

