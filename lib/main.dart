import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart'; // Importación para inicializar localización de fechas.
import 'services/local_database_service.dart';
import 'services/sync_service.dart';
import 'services/messaging_service.dart';
import 'services/user_data_util.dart';
import 'utils/routes.dart';
import 'utils/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Inicializa la localización para el formateo de fechas.
  await initializeDateFormatting();

  // Inicializa Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("Error initializing Firebase: $e");
  }

  // Habilita persistencia offline para Firebase Realtime Database
  FirebaseDatabase.instance.setPersistenceEnabled(true);

  // Habilita persistencia offline para Firestore
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  // Inicializa Hive para almacenamiento local
  await Hive.initFlutter();
  await LocalDatabaseService().init();

  // Actualiza o crea los datos del usuario en Firestore
  await createOrUpdateUserData();

  // Inicializa notificaciones push
  MessagingService().initialize();

  // Inicia monitoreo de conectividad para sincronización automática
  SyncService().startMonitoring();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/translations',
      fallbackLocale: const Locale('es'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comercio Fenix v1',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: Routes.login,
      routes: Routes.getRoutes(),
    );
  }
}
