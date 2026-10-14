import 'package:flutter/material.dart';

/// Sección de la barra inferior que todavía no tiene contenido (fase 5).
class UpcomingScreen extends StatelessWidget {
  const UpcomingScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('Llega en una próxima versión.')),
    );
  }
}
