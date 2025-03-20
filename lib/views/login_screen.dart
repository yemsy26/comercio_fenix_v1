import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  /// Inicia sesión con email y contraseña. Si falla, intenta registrar al usuario.
  Future<void> _signInWithEmail() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final user = await _authService.signInWithEmail(email, password);
    if (user != null) {
      // Forzar la actualización del token para obtener custom claims actualizados.
      await user.getIdToken(true);
      // Obtén y muestra los claims para depuración.
      final idTokenResult = await user.getIdTokenResult();
      print("Custom claims: ${idTokenResult?.claims}");
      Navigator.pushReplacementNamed(context, Routes.home);
    } else {
      // Si no se pudo iniciar sesión, intenta registrar al usuario.
      final newUser = await _authService.registerWithEmail(email, password);
      if (newUser != null) {
        await newUser.getIdToken(true);
        final idTokenResult = await newUser.getIdTokenResult();
        print("Custom claims: ${idTokenResult?.claims}");
        Navigator.pushReplacementNamed(context, Routes.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error en inicio de sesión o registro")),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  /// Inicia sesión con Google y fuerza la actualización del token.
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    final user = await _authService.signInWithGoogle();
    if (user != null) {
      await user.getIdToken(true);
      final idTokenResult = await user.getIdTokenResult();
      print("Custom claims: ${idTokenResult?.claims}");
      Navigator.pushReplacementNamed(context, Routes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error en inicio de sesión con Google")),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.red.shade700, Colors.red.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Comercio Fenix v1",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
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
                const SizedBox(height: 24),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _signInWithEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Iniciar Sesión",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Image.asset('assets/google.png', height: 24),
                  label: Text(
                    _isLoading ? "Cargando..." : "Iniciar con Google",
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, Routes.registro);
                  },
                  child: const Text(
                    "¿No tienes cuenta? Regístrate",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
