import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Inicia sesión con email y contraseña y fuerza la actualización del token para reflejar los custom claims.
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      var result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = result.user;
      if (user != null) {
        // Forzamos la actualización del token para obtener los custom claims recientes.
        await user.getIdToken(true);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException (signInWithEmail): ${e.message}");
      return null;
    } catch (e) {
      print("Error en signInWithEmail: $e");
      return null;
    }
  }

  /// Registra un nuevo usuario con email y contraseña y fuerza la actualización del token.
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      var result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = result.user;
      if (user != null) {
        await user.getIdToken(true);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException (registerWithEmail): ${e.message}");
      return null;
    } catch (e) {
      print("Error en registerWithEmail: $e");
      return null;
    }
  }

  /// Inicia sesión con Google y fuerza la actualización del token.
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // El usuario canceló la operación.
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user != null) {
        await user.getIdToken(true);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print("FirebaseAuthException (signInWithGoogle): ${e.message}");
      return null;
    } catch (e) {
      print("Error en signInWithGoogle: $e");
      return null;
    }
  }

  /// Cierra la sesión.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print("Error al cerrar sesión: $e");
    }
  }

  // --- Nuevos métodos para actualizar el perfil del usuario ---

  /// Retorna el usuario actual (o null si no hay sesión).
  User? get currentUser => _auth.currentUser;

  /// Actualiza el perfil del usuario con un nuevo displayName y, opcionalmente, una imagen de perfil.
  /// Si se proporciona una imagen, ésta se sube a Firebase Storage y se actualiza el photoURL.
  Future<void> updateUserProfile(String displayName, XFile? imageFile) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Actualiza el displayName.
      await user.updateDisplayName(displayName);

      // Si se proporciona una imagen, se sube a Storage y se actualiza el photoURL.
      if (imageFile != null) {
        final File file = File(imageFile.path);
        // Ruta: 'profile_images/{uid}.jpg'
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${user.uid}.jpg');
        UploadTask uploadTask = storageRef.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        final url = await snapshot.ref.getDownloadURL();
        await user.updatePhotoURL(url);
      }

      // Recarga la información del usuario para reflejar los cambios.
      await user.reload();
    } catch (e) {
      print("Error al actualizar perfil: $e");
    }
  }
}
