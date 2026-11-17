import 'package:flutter/material.dart';

import 'alerts.dart';
import 'data.dart';
import 'ui.dart';

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
        ? Icons.error_outline
        : (level == 1 ? Icons.warning_amber_rounded : Icons.info_outline);
    String tagOf(int level) => level == 2 ? 'Critique' : (level == 1 ? 'À surveiller' : 'Information');

    final nCrit = items.where((a) => a.level == 2).length;
    final nWatch = items.where((a) => a.level == 1).length;
    final nInfo = items.where((a) => a.level == 0).length;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          PageHeader(
            title: 'Alertes et recommandations',
            subtitle: 'Analyse de ${data.monthLong(data.lastMonth)} comparée au mois précédent',
          ),
          Row(
            children: [
              Expanded(child: _Count('Critiques', nCrit, colorOf(2))),
              const SizedBox(width: 10),
              Expanded(child: _Count('À surveiller', nWatch, colorOf(1))),
              const SizedBox(width: 10),
              Expanded(child: _Count('Informations', nInfo, colorOf(0))),
            ],
          ),
          const SizedBox(height: 14),
          for (final a in items)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: panelDecoration(context),
              clipBehavior: Clip.antiAlias,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 5, color: colorOf(a.level)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(iconOf(a.level), size: 18, color: colorOf(a.level)),
                                const SizedBox(width: 6),
                                Text(tagOf(a.level).toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 10.5,
                                        letterSpacing: 0.8,
                                        color: colorOf(a.level),
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                            const SizedBox(height: 4),
                            Text(a.detail, style: TextStyle(color: cs.onSurface, height: 1.35)),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorOf(a.level).withAlpha(22),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.lightbulb_outline, size: 16, color: colorOf(a.level)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(a.reco,
                                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13, height: 1.35)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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

/// Compteur d'alertes par niveau.
class _Count extends StatelessWidget {
  final String label;
  final int n;
  final Color color;
  const _Count(this.label, this.n, this.color);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: panelDecoration(context),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$n', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}
