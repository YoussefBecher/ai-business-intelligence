import 'package:flutter/material.dart';

import 'alerts.dart';
import 'data.dart';

class AlertsPage extends StatelessWidget {
  final SalesData data;
  const AlertsPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final items = buildAlerts(data);

    Color colorOf(int level) => level == 2
        ? Colors.red.shade600
        : (level == 1 ? Colors.orange.shade700 : cs.primary);
    IconData iconOf(int level) => level == 2
        ? Icons.error
        : (level == 1 ? Icons.warning_amber_rounded : Icons.info_outline);
    String tagOf(int level) => level == 2 ? 'Critique' : (level == 1 ? 'À surveiller' : 'Information');

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Alertes et recommandations', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Analyse de ${data.monthLong(data.lastMonth)} comparée au mois précédent.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
          const SizedBox(height: 12),
          for (final a in items)
            Card(
              elevation: 0,
              color: colorOf(a.level).withAlpha(24),
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(iconOf(a.level), color: colorOf(a.level)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tagOf(a.level).toUpperCase(),
                              style: TextStyle(fontSize: 10.5, letterSpacing: 0.8, color: colorOf(a.level), fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(a.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(a.detail),
                          const SizedBox(height: 8),
                          Text('Recommandation : ${a.reco}', style: TextStyle(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
