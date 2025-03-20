import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      _userDataFuture = FirebaseFirestore.instance.collection('userData').doc(uid).get();
    } else {
      _userDataFuture = Future.value(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil de Usuario"),
        backgroundColor: Colors.red.shade700,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
            return const Center(child: Text("No hay datos disponibles para este usuario."));
          }
          final data = snapshot.data!.data()!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: (data['photoUrl'] != null && (data['photoUrl'] as String).isNotEmpty)
                      ? NetworkImage(data['photoUrl'])
                      : null,
                  child: (data['photoUrl'] == null || (data['photoUrl'] as String).isEmpty)
                      ? const Icon(Icons.person, size: 40)
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  data['name'] ?? 'Usuario',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("Email: ${data['email'] ?? 'Sin email'}", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Aquí puedes navegar a una pantalla de edición de perfil
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
                  child: const Text("Editar Perfil"),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
