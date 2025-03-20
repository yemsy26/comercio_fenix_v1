import 'package:flutter/material.dart';
import 'package:comercio_fenix_v1/views/login_screen.dart';
import 'package:comercio_fenix_v1/views/registro_screen.dart';
import 'package:comercio_fenix_v1/views/home_screen.dart';
import 'package:comercio_fenix_v1/views/client_management_screen.dart';
import 'package:comercio_fenix_v1/views/inventory_screen.dart';
import 'package:comercio_fenix_v1/views/invoice_screen.dart';
import 'package:comercio_fenix_v1/views/reports_screen.dart';
import 'package:comercio_fenix_v1/views/settings_screen.dart';
import 'package:comercio_fenix_v1/views/user_profile_screen.dart';

class Routes {
  static const String login = '/login';
  static const String registro = '/registro';
  static const String home = '/home';
  static const String clients = '/clients';
  static const String inventory = '/inventory';
  static const String invoice = '/invoice';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      registro: (context) => const RegistroScreen(),
      home: (context) => const HomeScreen(),
      clients: (context) => const ClientManagementScreen(),
      inventory: (context) => const InventoryScreen(),
      invoice: (context) => const InvoiceScreen(),
      reports: (context) => const ReportsScreen(),
      settings: (context) => const SettingsScreen(),
      profile: (context) => const UserProfileScreen(),
    };
  }
}

