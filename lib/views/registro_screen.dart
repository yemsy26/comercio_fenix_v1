import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/routes.dart';
import '../services/user_data_util.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({Key? key}) : super(key: key);

  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = await _authService.registerWithEmail(email, password);
    if (user != null) {
      await createOrUpdateUserData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cuenta creada correctamente")),
      );
      Navigator.pushReplacementNamed(context, Routes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error en la creación de cuenta")),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro"),
        backgroundColor: Colors.red.shade700,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade700, Colors.red.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.red.shade700, Colors.red.shade900],
                    ),
                  ),
                  child: const Icon(Icons.person_add, color: Colors.white, size: 60),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Crear Cuenta",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Correo electrónico',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.email, color: Colors.redAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Contraseña',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.lock, color: Colors.redAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Confirmar Contraseña',
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.redAccent),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Registrar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
