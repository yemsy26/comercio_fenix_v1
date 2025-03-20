class UserModel {
  final String uid;
  final String email;
  final String role; // "admin", "employee", "seller", etc.

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      role: data['role'] ?? 'seller',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
    };
  }
}
