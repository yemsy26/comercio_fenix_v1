import 'package:firebase_messaging/firebase_messaging.dart';

class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      await _messaging.requestPermission();
      String? token = await _messaging.getToken();
      print("FCM Token: $token");

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Notificación recibida: ${message.notification?.title} - ${message.notification?.body}');
      });
    } catch (e) {
      print("Error inicializando notificaciones: $e");
    }
  }
}
