import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';

/// Resto de secciones. Las que aún no tienen pantalla salen como «Próximamente» (fase 5).
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  static const _sections = [
    (Icons.auto_stories_outlined, 'Resúmenes', Routes.summaries),
    (Icons.notifications_outlined, 'Recordatorios', null),
    (Icons.bar_chart, 'Estadísticas', null),
    (Icons.sell_outlined, 'Categorías', null),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Más')),
      body: ListView(
        children: [
          for (final (icon, title, route) in _sections)
            ListTile(
              enabled: route != null,
              leading: Icon(icon),
              title: Text(title),
              subtitle: route == null ? const Text('Próximamente') : null,
              trailing: route == null ? null : const Icon(Icons.chevron_right),
              onTap: route == null ? null : () => context.go(route),
            ),
        ],
      ),
    );
  }
}
