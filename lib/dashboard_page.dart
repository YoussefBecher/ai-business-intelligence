import 'package:flutter/material.dart';

import 'charts.dart';
import 'data.dart';
import 'fmt.dart';
import 'ui.dart';

class DashboardPage extends StatefulWidget {
  final SalesData data;
  const DashboardPage({super.key, required this.data});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int? year; // null = toutes les années
  int? region; // null = toutes les régions

  SalesData get d => widget.data;

  bool _inYear(int m) => year == null || d.yearOf(m) == year;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = d.agg(where: _inYear, region: region);

    final monthly = d.monthlyCa(region: region);
    var lastSel = 0;
    for (var m = 0; m < d.months.length; m++) {
      if (_inYear(m)) lastSel = m;
    }
    final growth = lastSel > 0 && monthly[lastSel - 1] > 0
        ? monthly[lastSel] / monthly[lastSel - 1] - 1
        : null;

    final idx = [for (var m = 0; m < d.months.length; m++) if (_inYear(m)) m];
    final labels = idx.map(d.monthShort).toList();
    final real = idx.map<double?>((m) => monthly[m]).toList();

    final regAgg = [for (var r = 0; r < d.regions.length; r++) d.agg(where: _inYear, region: r)];
    final order = List<int>.generate(d.regions.length, (i) => i)
      ..sort((x, y) => regAgg[y].ca.compareTo(regAgg[x].ca));
    final maxCa = regAgg.map((e) => e.ca).reduce((p, q) => p > q ? p : q);

    final stats = d.productStats(where: _inYear, region: region)
      ..sort((x, y) => y.marge.compareTo(x.marge));
    final top = stats.take(5).toList();

    final real100 = a.real;
    final kpis = <_Kpi>[
      _Kpi("Chiffre d'affaires", fmtM(a.ca), year == null ? '2024 à 2026' : '$year', Icons.payments_outlined),
      _Kpi('Marge', fmtM(a.marge), 'sur ${fmtM(a.ca)} de CA', Icons.account_balance_wallet_outlined),
      _Kpi('Marge bénéficiaire', fmtPct(a.margePct), 'marge ÷ CA', Icons.percent),
      _Kpi('Panier moyen', fmtInt(a.panier), '${fmtInt(a.nOrders)} commandes', Icons.shopping_basket_outlined),
      _Kpi('Réalisation objectif', real100 == null ? '–' : fmtPct(real100, 0), 'objectif ${fmtM(a.obj)}',
          Icons.flag_outlined,
          color: real100 == null
              ? null
              : (real100 >= 1 ? Colors.green.shade600 : (real100 >= .9 ? Colors.orange.shade700 : Colors.red.shade600))),
      _Kpi('Croissance mensuelle', growth == null ? '–' : fmtSigned(growth),
          lastSel > 0 ? '${d.monthShort(lastSel)} vs ${d.monthShort(lastSel - 1)}' : '',
          growth != null && growth < 0 ? Icons.trending_down : Icons.trending_up,
          color: growth == null ? null : (growth >= 0 ? Colors.green.shade600 : Colors.red.shade600)),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const PageHeader(
            title: 'Tableau de bord',
            subtitle: 'Vue d\'ensemble des ventes et de la rentabilité',
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final y in <int?>[null, 2024, 2025, 2026])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(y == null ? 'Toutes' : '$y'),
                      selected: year == y,
                      onSelected: (_) => setState(() => year = y),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            value: region,
            decoration: InputDecoration(
              labelText: 'Région',
              prefixIcon: const Icon(Icons.place_outlined),
              filled: true,
              fillColor: panelColorOf(context),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Toutes les régions')),
              for (var r = 0; r < d.regions.length; r++) DropdownMenuItem<int?>(value: r, child: Text(d.regions[r])),
            ],
            onChanged: (v) => setState(() => region = v),
          ),
          const SizedBox(height: 16),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 230,
              mainAxisExtent: 112,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            children: [for (final k in kpis) _KpiCard(k)],
          ),
          const SizedBox(height: 16),
          Panel(
            title: 'Chiffre d\'affaires mensuel',
            child: SeriesChart(labels: labels, real: real),
          ),
          const SizedBox(height: 14),
          Panel(
            title: 'Régions',
            subtitle: 'Touchez une région pour filtrer',
            child: Column(
              children: [
                for (final r in order)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => region = region == r ? null : r),
                    child: Container(
                      decoration: BoxDecoration(
                        color: region == r ? cs.primaryContainer.withAlpha(110) : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 70, child: Text(d.regions[r], style: const TextStyle(fontWeight: FontWeight.w500))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: regAgg[r].ca / maxCa, minHeight: 9),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 92,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(fmtM(regAgg[r].ca), style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text('marge ${fmtPct(regAgg[r].margePct)}',
                                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
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
          const SizedBox(height: 14),
          Panel(
            title: 'Produits les plus rentables',
            subtitle: 'Classés par marge',
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                for (var k = 0; k < top.length; k++) ...[
                  if (k > 0) Divider(height: 1, color: cs.outlineVariant.withAlpha(120)),
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: cs.primaryContainer,
                      child: Text('${k + 1}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onPrimaryContainer)),
                    ),
                    title: Text(d.products[top[k].i].name),
                    subtitle: Text('${d.products[top[k].i].category} · ${d.products[top[k].i].sub}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(fmtInt(top[k].marge), style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(fmtPct(top[k].margePct), style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                      ],
                    ),
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

class _Kpi {
  final String label, value, sub;
  final IconData icon;
  final Color? color;
  _Kpi(this.label, this.value, this.sub, this.icon, {this.color});
}

class _KpiCard extends StatelessWidget {
  final _Kpi k;
  const _KpiCard(this.k);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: panelDecoration(context),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  k.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
              ),
              Icon(k.icon, size: 18, color: k.color ?? cs.primary),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(k.value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: k.color ?? cs.onSurface)),
          ),
          const SizedBox(height: 2),
          Text(k.sub, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
