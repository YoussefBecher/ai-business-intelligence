import 'package:flutter/material.dart';

import 'charts.dart';
import 'data.dart';
import 'fmt.dart';

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
    final nh = 12; // mois d'historique affichés
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
    final weeks = _weeks(12);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Prévisions des ventes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Modèle Holt-Winters, intervalle d\'environ 95 %, toutes régions.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Par mois'), icon: Icon(Icons.calendar_month)),
              ButtonSegment(value: true, label: Text('Par semaine'), icon: Icon(Icons.view_week)),
            ],
            selected: {weekly},
            onSelectionChanged: (s) => setState(() => weekly = s.first),
          ),
          const SizedBox(height: 16),
          if (!weekly) ...[
            SeriesChart(
              labels: labels,
              real: real,
              fc: series((x) => x.mid),
              lo: series((x) => x.lo),
              hi: series((x) => x.hi),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: cs.primaryContainer.withAlpha(120),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text('CA cumulé prévu sur ${d.forecast.length} mois : ${fmtM(total)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            for (var k = 0; k < d.forecast.length; k++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(d.forecastLong(k)),
                subtitle: Text('de ${fmtInt(d.forecast[k].lo)} à ${fmtInt(d.forecast[k].hi)}'),
                trailing: Text(fmtInt(d.forecast[k].mid), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
          ] else ...[
            Text(
              'Estimation : la prévision de chaque mois est répartie à parts égales entre ses jours, puis additionnée par semaine.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            for (final w in weeks)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(w.label),
                subtitle: Text('de ${fmtInt(w.lo)} à ${fmtInt(w.hi)}'),
                trailing: Text(fmtInt(w.mid), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
          ],
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
