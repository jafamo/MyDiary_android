import 'package:flutter/material.dart';

/// Resto de secciones. De momento, todas pendientes (fase 5).
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _sections = [
    (Icons.auto_stories_outlined, 'Resúmenes'),
    (Icons.notifications_outlined, 'Recordatorios'),
    (Icons.bar_chart, 'Estadísticas'),
    (Icons.sell_outlined, 'Temas'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Más')),
      body: ListView(
        children: [
          for (final (icon, title) in _sections)
            ListTile(
              enabled: false,
              leading: Icon(icon),
              title: Text(title),
              subtitle: const Text('Próximamente'),
            ),
        ],
      ),
    );
  }
}
