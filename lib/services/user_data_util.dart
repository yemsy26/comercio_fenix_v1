import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> createOrUpdateUserData() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    final userData = {
      'name': user.displayName ?? user.email ?? 'Usuario',
      'photoUrl': user.photoURL ?? '',
      'phone': '',
      'address': '',
      'ownerEmail': user.email,
      'lastUpdated': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('userData')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));
      print("User data updated for ${user.uid}");
    } catch (e) {
      print("Error updating user data for ${user.uid}: $e");
    }
  } else {
    print("No user signed in.");
  }
}
