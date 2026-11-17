import 'package:flutter/material.dart';

import 'charts.dart';
import 'data.dart';
import 'fmt.dart';
import 'ui.dart';

class ForecastPage extends StatefulWidget {
  final SalesData data;
  const ForecastPage({super.key, required this.data});

  @override
  State<ForecastPage> createState() => _ForecastPageState();
}

class _ForecastPageState extends State<ForecastPage> {
  bool weekly = false;

  SalesData get d => widget.data;

  int _daysIn(int y, int m) => DateTime(y, m + 1, 0).day;

  /// Prévision hebdomadaire estimée : la prévision du mois est répartie à parts égales sur ses jours.
  List<_Week> _weeks(int count) {
    final m0 = d.monthOf(d.lastMonth);
    final y0 = d.yearOf(d.lastMonth);
    var start = DateTime(y0 + (m0 == 12 ? 1 : 0), m0 == 12 ? 1 : m0 + 1, 1);
    final out = <_Week>[];
    for (var w = 0; w < count; w++) {
      var mid = 0.0, lo = 0.0, hi = 0.0;
      var ok = true;
      for (var k = 0; k < 7; k++) {
        final day = start.add(Duration(days: w * 7 + k));
        final k0 = (day.year - start.year) * 12 + day.month - start.month;
        if (k0 < 0 || k0 >= d.forecast.length) {
          ok = false;
          break;
        }
        final n = _daysIn(day.year, day.month);
        mid += d.forecast[k0].mid / n;
        lo += d.forecast[k0].lo / n;
        hi += d.forecast[k0].hi / n;
      }
      if (!ok) break;
      final from = start.add(Duration(days: w * 7));
      final to = from.add(const Duration(days: 6));
      out.add(_Week('${from.day} ${monthShortNames[from.month - 1]} – ${to.day} ${monthShortNames[to.month - 1]}', mid, lo, hi));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final monthly = d.monthlyCa();
    const nh = 12; // mois d'historique affichés
    final start = monthly.length - nh;

    final labels = <String>[
      for (var m = start; m < monthly.length; m++) d.monthShort(m),
      for (var k = 0; k < d.forecast.length; k++) d.forecastShort(k),
    ];
    final lastReal = monthly.last;
    final real = <double?>[
      for (var m = start; m < monthly.length; m++) monthly[m],
      for (var k = 0; k < d.forecast.length; k++) null,
    ];
    List<double?> series(double Function(Fc) f) => <double?>[
          for (var i = 0; i < nh - 1; i++) null,
          lastReal,
          for (final x in d.forecast) f(x),
        ];

    final total = d.forecast.fold<double>(0, (s, x) => s + x.mid);
    final avg = d.forecast.isEmpty ? 0.0 : total / d.forecast.length;
    final nf = d.forecast.length;
    final prev = nf > 0 && monthly.length >= nf
        ? monthly.sublist(monthly.length - nf).fold<double>(0, (s, x) => s + x)
        : 0.0;
    final delta = prev > 0 ? total / prev - 1 : null;
    final weeks = _weeks(12);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const PageHeader(
            title: 'Prévisions des ventes',
            subtitle: 'Modèle Holt-Winters, intervalle de confiance d\'environ 95 %, toutes régions',
          ),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Par mois'), icon: Icon(Icons.calendar_month)),
              ButtonSegment(value: true, label: Text('Par semaine'), icon: Icon(Icons.view_week)),
            ],
            selected: {weekly},
            onSelectionChanged: (s) => setState(() => weekly = s.first),
          ),
          const SizedBox(height: 14),
          if (!weekly) ...[
            Row(
              children: [
                Expanded(child: _Stat('Total $nf mois', fmtM(total), 'CA prévu')),
                const SizedBox(width: 10),
                Expanded(child: _Stat('Moyenne', fmtM(avg), 'par mois')),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    'Évolution',
                    delta == null ? '–' : fmtSigned(delta),
                    'vs $nf mois réels',
                    color: delta == null ? null : (delta >= 0 ? Colors.green.shade600 : Colors.red.shade600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Panel(
              title: 'Chiffre d\'affaires : réel et prévu',
              subtitle: '12 derniers mois et $nf mois de prévision',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Legend(),
                  const SizedBox(height: 10),
                  SeriesChart(
                    labels: labels,
                    real: real,
                    fc: series((x) => x.mid),
                    lo: series((x) => x.lo),
                    hi: series((x) => x.hi),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Panel(
              title: 'Détail par mois',
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Column(
                children: [
                  for (var k = 0; k < d.forecast.length; k++) ...[
                    if (k > 0) Divider(height: 1, color: cs.outlineVariant.withAlpha(120)),
                    _FcRow(
                      title: d.forecastLong(k),
                      range: 'de ${fmtInt(d.forecast[k].lo)} à ${fmtInt(d.forecast[k].hi)}',
                      value: fmtInt(d.forecast[k].mid),
                    ),
                  ],
                ],
              ),
            ),
          ] else
            Panel(
              title: 'Prévision par semaine',
              subtitle: 'Estimation : la prévision de chaque mois est répartie à parts égales entre ses jours, puis additionnée par semaine.',
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
              child: Column(
                children: [
                  for (var k = 0; k < weeks.length; k++) ...[
                    if (k > 0) Divider(height: 1, color: cs.outlineVariant.withAlpha(120)),
                    _FcRow(
                      title: weeks[k].label,
                      range: 'de ${fmtInt(weeks[k].lo)} à ${fmtInt(weeks[k].hi)}',
                      value: fmtInt(weeks[k].mid),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Week {
  final String label;
  final double mid, lo, hi;
  _Week(this.label, this.mid, this.lo, this.hi);
}

/// Petite carte de synthèse : libellé, valeur, précision.
class _Stat extends StatelessWidget {
  final String label, value, sub;
  final Color? color;
  const _Stat(this.label, this.value, this.sub, {this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: panelDecoration(context),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color ?? cs.onSurface)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(sub, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

/// Ligne de détail : période, fourchette et valeur centrale.
class _FcRow extends StatelessWidget {
  final String title, range, value;
  const _FcRow({required this.title, required this.range, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(range, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ],
      ),
    );
  }
}

/// Légende du graphique : série réelle, prévision et intervalle.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const fc = Color(0xFFD9822B);
    Widget item(Widget swatch, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            swatch,
            const SizedBox(width: 6),
            Text(text, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        );
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        item(Container(width: 18, height: 3, color: cs.primary), 'CA réel'),
        item(Container(width: 18, height: 3, color: fc), 'Prévision'),
        item(Container(width: 18, height: 10, color: fc.withAlpha(60)), 'Intervalle 95 %'),
      ],
    );
  }
}
