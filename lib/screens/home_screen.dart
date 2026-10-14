import 'package:flutter/material.dart';

/// Provisional: la portada (Diario) llega en la fase 2.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyDiary')),
      body: const Center(child: Text('Diario')),
    );
  }
}
