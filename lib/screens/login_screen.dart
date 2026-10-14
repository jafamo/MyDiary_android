import 'package:flutter/material.dart';

/// Provisional: el formulario de login llega en la fase 1.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyDiary')),
      body: const Center(child: Text('Iniciar sesión')),
    );
  }
}
