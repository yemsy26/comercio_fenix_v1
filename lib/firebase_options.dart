// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAF9ZToymXP9rgSpC0LvNUPTJlmuNZkOjY',
    appId: '1:536767845139:web:9968c3349a306bb24a80e6',
    messagingSenderId: '536767845139',
    projectId: 'comercio-fenix-056-14e87',
    authDomain: 'comercio-fenix-056-14e87.firebaseapp.com',
    storageBucket: 'comercio-fenix-056-14e87.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCippPqWPCSSUXM8mVgrGSxSkD6nK6AJl0',
    appId: '1:536767845139:android:fae85cc21e5f7bcc4a80e6',
    messagingSenderId: '536767845139',
    projectId: 'comercio-fenix-056-14e87',
    storageBucket: 'comercio-fenix-056-14e87.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAqyYqhiBjZva_01l_AU5IOKGGSngGpKmM',
    appId: '1:536767845139:ios:28f62ba934a89c2e4a80e6',
    messagingSenderId: '536767845139',
    projectId: 'comercio-fenix-056-14e87',
    storageBucket: 'comercio-fenix-056-14e87.firebasestorage.app',
    androidClientId: '536767845139-29h567poia5rpto8cahmtb6uiah3sbef.apps.googleusercontent.com',
    iosClientId: '536767845139-ultn8b46j7avj9sre2nqdlbvnfkcgcpj.apps.googleusercontent.com',
    iosBundleId: 'com.example.comerciofenix056.comercioFenixV1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAqyYqhiBjZva_01l_AU5IOKGGSngGpKmM',
    appId: '1:536767845139:ios:28f62ba934a89c2e4a80e6',
    messagingSenderId: '536767845139',
    projectId: 'comercio-fenix-056-14e87',
    storageBucket: 'comercio-fenix-056-14e87.firebasestorage.app',
    androidClientId: '536767845139-29h567poia5rpto8cahmtb6uiah3sbef.apps.googleusercontent.com',
    iosClientId: '536767845139-ultn8b46j7avj9sre2nqdlbvnfkcgcpj.apps.googleusercontent.com',
    iosBundleId: 'com.example.comerciofenix056.comercioFenixV1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAF9ZToymXP9rgSpC0LvNUPTJlmuNZkOjY',
    appId: '1:536767845139:web:a06bc48c3011e84b4a80e6',
    messagingSenderId: '536767845139',
    projectId: 'comercio-fenix-056-14e87',
    authDomain: 'comercio-fenix-056-14e87.firebaseapp.com',
    storageBucket: 'comercio-fenix-056-14e87.firebasestorage.app',
  );
}
