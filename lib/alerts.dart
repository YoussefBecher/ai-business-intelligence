import 'data.dart';
import 'fmt.dart';

/// Niveau : 2 = critique, 1 = à surveiller, 0 = information.
class AlertItem {
  final int level;
  final String title, detail, reco;
  const AlertItem(this.level, this.title, this.detail, this.reco);
}

/// Détection de baisses et de risques sur le dernier mois de l'historique.
/// Règles : baisse du CA > 5 % (à surveiller) ou > 10 % (critique), objectif < 90 % ou < 80 %,
/// produits dont le taux de marge est inférieur de 3 points à la moyenne, baisse prévue > 8 %.
List<AlertItem> buildAlerts(SalesData d) {
  final out = <AlertItem>[];
  final last = d.lastMonth, prev = last - 1;
  final lm = d.monthLong(last), pm = d.monthLong(prev);

  final a0 = d.agg(where: (m) => m == prev);
  final a1 = d.agg(where: (m) => m == last);
  final g = a0.ca == 0 ? 0.0 : a1.ca / a0.ca - 1;
  if (g < -0.10) {
    out.add(AlertItem(2, 'Forte baisse du chiffre d\'affaires',
        'Le CA de $lm recule de ${fmtPct(-g)} par rapport à $pm.',
        'Identifier les régions et les produits en cause, puis lancer une action commerciale ciblée.'));
  } else if (g < -0.05) {
    out.add(AlertItem(1, 'Baisse du chiffre d\'affaires',
        'Le CA de $lm recule de ${fmtPct(-g)} par rapport à $pm.',
        'Surveiller la tendance le mois prochain et relancer les clients les plus actifs.'));
  } else if (g < 0) {
    out.add(AlertItem(0, 'Légère baisse du chiffre d\'affaires',
        'Le CA de $lm recule de ${fmtPct(-g)} par rapport à $pm, ce qui reste dans la variation habituelle.',
        'Aucune action urgente : suivre l\'évolution.'));
  } else {
    out.add(AlertItem(0, 'Chiffre d\'affaires en hausse',
        'Le CA de $lm progresse de ${fmtPct(g)} par rapport à $pm.',
        'Capitaliser sur les régions et produits qui portent la hausse.'));
  }

  for (var r = 0; r < d.regions.length; r++) {
    final name = d.regions[r];
    final r0 = d.agg(where: (m) => m == prev, region: r);
    final r1 = d.agg(where: (m) => m == last, region: r);
    final gr = r0.ca == 0 ? 0.0 : r1.ca / r0.ca - 1;
    if (gr < -0.10) {
      out.add(AlertItem(2, 'Baisse à $name',
          'Le CA de $name chute de ${fmtPct(-gr)} entre $pm et $lm.',
          'Analyser les ventes par produit dans cette région, relancer les clients inactifs et vérifier les remises.'));
    } else if (gr < -0.05) {
      out.add(AlertItem(1, 'Recul à $name',
          'Le CA de $name baisse de ${fmtPct(-gr)} entre $pm et $lm.',
          'Suivre la région de près et comparer avec les mois habituellement faibles.'));
    }
    final real = r1.real;
    if (real != null && real < 0.80) {
      out.add(AlertItem(2, 'Objectif très loin à $name',
          'En $lm, $name n\'atteint que ${fmtPct(real, 0)} de son objectif.',
          'Revoir le plan d\'action commercial ou ajuster l\'objectif du mois suivant.'));
    } else if (real != null && real < 0.90) {
      out.add(AlertItem(1, 'Objectif en retard à $name',
          'En $lm, $name atteint ${fmtPct(real, 0)} de son objectif.',
          'Concentrer les efforts commerciaux sur les produits à forte marge.'));
    }
  }

  // Produits dont la marge est nettement sous la moyenne sur 12 mois.
  final stats = d.productStats(where: (m) => m > last - 12);
  var ca = 0.0, mg = 0.0;
  for (final s in stats) {
    ca += s.ca;
    mg += s.marge;
  }
  final avg = ca == 0 ? 0.0 : mg / ca;
  final low = stats.where((s) => s.margePct < avg - 0.03).toList()
    ..sort((a, b) => a.margePct.compareTo(b.margePct));
  if (low.isNotEmpty) {
    final names = low.take(3).map((s) => '${d.products[s.i].name} (${fmtPct(s.margePct)})').join(', ');
    out.add(AlertItem(1, 'Produits à faible marge',
        'Sur 12 mois, ces produits ont un taux de marge nettement sous la moyenne de ${fmtPct(avg)} : $names.',
        'Réviser les prix ou limiter les remises sur ces produits.'));
  }

  // Baisse prévue le mois prochain.
  final next = d.forecast.first.mid;
  final ch = a1.ca == 0 ? 0.0 : next / a1.ca - 1;
  final nl = d.forecastLong(0);
  if (ch < -0.08) {
    out.add(AlertItem(1, 'Baisse anticipée en $nl',
        'La prévision de $nl (${fmtInt(next)}) est ${fmtPct(-ch)} sous le CA de $lm.',
        'Prévoir une promotion ou une campagne avant ce mois et ajuster les stocks.'));
  } else {
    out.add(AlertItem(0, 'Prévision de $nl',
        'Le CA prévu pour $nl est de ${fmtInt(next)}, soit ${fmtSigned(ch)} par rapport à $lm.',
        'Aucune action particulière.'));
  }

  out.sort((a, b) => b.level.compareTo(a.level));
  return out;
}
