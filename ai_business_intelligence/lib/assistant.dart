import 'alerts.dart';
import 'data.dart';
import 'fmt.dart';

class _Per {
  final bool Function(int) where;
  final String label;
  final int? month, year;
  _Per(this.where, this.label, this.month, this.year);
}

/// Assistant conversationnel sans connexion : il reconnaît l'intention de la question
/// (CA, marge, objectifs, régions, produits, prévisions, alertes), repère la période
/// et la région citées, puis calcule la réponse directement sur les données.
class Assistant {
  final SalesData d;
  Assistant(this.d);

  static const _mois = [
    'janvier', 'fevrier', 'mars', 'avril', 'mai', 'juin',
    'juillet', 'aout', 'septembre', 'octobre', 'novembre', 'decembre'
  ];

  static const suggestions = [
    'Quel est le chiffre d\'affaires de 2026 ?',
    'Quelle est la meilleure région ?',
    'Quels sont les produits les plus rentables ?',
    'Quelle est la prévision pour le mois prochain ?',
    'Y a-t-il des alertes ?',
    'Taux de réalisation des objectifs à Tunis',
  ];

  static const helpText =
      'Je réponds aux questions sur les ventes, par exemple :\n'
      '• « Chiffre d\'affaires en mars 2026 »\n'
      '• « Marge à Sfax en 2025 »\n'
      '• « Meilleure région » ou « classement des régions »\n'
      '• « Produits les plus rentables » ou « les moins rentables »\n'
      '• « Taux de réalisation des objectifs »\n'
      '• « Croissance du dernier mois »\n'
      '• « Prévision du mois prochain »\n'
      '• « Alertes et recommandations »';

  String _norm(String s) {
    var t = s.toLowerCase();
    const from = 'àâäéèêëîïôöùûüç’\'';
    const to = 'aaaeeeeiioouuuc  ';
    for (var i = 0; i < from.length; i++) {
      t = t.replaceAll(from[i], to[i]);
    }
    return t;
  }

  _Per _period(String q) {
    final ym = RegExp(r'\b(2024|2025|2026)\b').firstMatch(q);
    final int? year = ym == null ? null : int.parse(ym.group(1)!);
    int? mo;
    for (var i = 0; i < 12; i++) {
      if (RegExp('\\b${_mois[i]}\\b').hasMatch(q)) {
        mo = i + 1;
        break;
      }
    }
    if (q.contains('dernier mois') || q.contains('mois dernier') || q.contains('ce mois')) {
      final l = d.lastMonth;
      return _Per((m) => m == l, d.monthLong(l), d.monthOf(l), d.yearOf(l));
    }
    if (mo != null) {
      final y = year ?? d.yearOf(d.lastMonth);
      final key = '$y-${mo.toString().padLeft(2, '0')}';
      final idx = d.months.indexOf(key);
      if (idx >= 0) {
        return _Per((m) => m == idx, d.monthLong(idx), mo, y);
      }
      return _Per((m) => false, '$key (hors période)', mo, y);
    }
    if (year != null) {
      return _Per((m) => d.yearOf(m) == year, 'en $year', null, year);
    }
    return _Per((m) => true, 'sur toute la période (2024 à 2026)', null, null);
  }

  String answer(String raw) {
    final q = _norm(raw).trim();
    if (q.isEmpty) return helpText;
    final per = _period(q);
    final where = per.where;

    int? region;
    for (var i = 0; i < d.regions.length; i++) {
      if (q.contains(_norm(d.regions[i]))) {
        region = i;
        break;
      }
    }
    final scope = region == null ? 'toutes régions' : d.regions[region];
    bool has(List<String> w) => w.any((k) => q.contains(k));

    if (has(['aide', 'help', 'que peux', 'bonjour', 'salut', 'hello'])) {
      return helpText;
    }

    if (has(['prevision', 'prevoir', 'prochain', 'futur', '2027', 'predic'])) {
      final f = d.forecast;
      final total = f.fold<double>(0, (s, x) => s + x.mid);
      final extra = region != null ? '\n(La prévision porte sur l\'ensemble des régions.)' : '';
      return 'Prévision pour ${d.forecastLong(0)} : ${fmtInt(f[0].mid)} '
          '(intervalle de ${fmtInt(f[0].lo)} à ${fmtInt(f[0].hi)}).\n'
          'Sur les ${f.length} prochains mois, le CA cumulé attendu est de ${fmtM(total)}.$extra';
    }

    if (has(['baisse', 'alerte', 'probleme', 'chute', 'risque', 'recul', 'recommand'])) {
      final alerts = buildAlerts(d).where((a) => a.level > 0).toList();
      if (alerts.isEmpty) {
        return 'Aucune alerte importante sur ${d.monthLong(d.lastMonth)}.';
      }
      final b = StringBuffer('${alerts.length} point(s) à surveiller :\n');
      for (final a in alerts.take(3)) {
        b.writeln('\n• ${a.title} : ${a.detail}\n  Conseil : ${a.reco}');
      }
      return b.toString().trim();
    }

    if (has(['produit', 'rentable', 'article'])) {
      final stats = d.productStats(where: where, region: region);
      if (stats.isEmpty) return 'Aucune vente sur cette période.';
      final worst = has(['moins', 'pire', 'faible', 'mauvais']);
      stats.sort((a, b) => worst ? a.marge.compareTo(b.marge) : b.marge.compareTo(a.marge));
      final b = StringBuffer(
          '${worst ? 'Produits les moins rentables' : 'Produits les plus rentables'} ${per.label} ($scope) :\n');
      var k = 1;
      for (final s in stats.take(3)) {
        b.writeln('$k. ${d.products[s.i].name} : marge ${fmtInt(s.marge)} (${fmtPct(s.margePct)})');
        k++;
      }
      return b.toString().trim();
    }

    if (region == null && has(['region', 'meilleur', 'pire', 'classement'])) {
      final list = <MapEntry<int, Agg>>[];
      for (var r = 0; r < d.regions.length; r++) {
        list.add(MapEntry(r, d.agg(where: where, region: r)));
      }
      list.sort((a, b) => b.value.ca.compareTo(a.value.ca));
      final b = StringBuffer('Classement des régions ${per.label} :\n');
      var k = 1;
      for (final e in list) {
        b.writeln('$k. ${d.regions[e.key]} : ${fmtM(e.value.ca)} (marge ${fmtPct(e.value.margePct)})');
        k++;
      }
      b.write('\nMeilleure région : ${d.regions[list.first.key]}. Plus faible : ${d.regions[list.last.key]}.');
      return b.toString();
    }

    if (has(['objectif', 'realisation', 'atteint', 'cible'])) {
      final a = d.agg(where: where, region: region);
      final r = a.real;
      if (r == null) return 'Il n\'y a pas d\'objectif défini ${per.label}.';
      return 'Réalisation des objectifs ${per.label} ($scope) : ${fmtPct(r, 0)}.\n'
          'CA réalisé ${fmtM(a.ca)} pour un objectif de ${fmtM(a.obj)}.';
    }

    if (has(['panier'])) {
      final a = d.agg(where: where, region: region);
      return 'Panier moyen ${per.label} ($scope) : ${fmtInt(a.panier)}, '
          'sur ${fmtInt(a.nOrders)} commandes.';
    }

    if (has(['croissance', 'evolution', 'progress', 'augment', 'hausse'])) {
      if (per.month == null && per.year != null) {
        final y = per.year!;
        final cur = d.agg(where: (m) => d.yearOf(m) == y, region: region);
        final pre = d.agg(where: (m) => d.yearOf(m) == y - 1, region: region);
        if (pre.ca == 0) return 'Pas d\'année précédente pour comparer avec $y.';
        return 'Croissance annuelle $y ($scope) : ${fmtSigned(cur.ca / pre.ca - 1)} '
            '(${fmtM(cur.ca)} contre ${fmtM(pre.ca)} en ${y - 1}).';
      }
      var idx = d.lastMonth;
      if (per.month != null) {
        idx = d.months.indexOf('${per.year}-${per.month.toString().padLeft(2, '0')}');
      }
      if (idx < 1) return 'Pas de mois précédent pour comparer.';
      final cur = d.agg(where: (m) => m == idx, region: region);
      final pre = d.agg(where: (m) => m == idx - 1, region: region);
      if (pre.ca == 0) return 'Pas de ventes le mois précédent pour comparer.';
      return 'Croissance mensuelle en ${d.monthLong(idx)} ($scope) : ${fmtSigned(cur.ca / pre.ca - 1)} '
          'par rapport à ${d.monthLong(idx - 1)} (${fmtM(cur.ca)} contre ${fmtM(pre.ca)}).';
    }

    if (has(['marge', 'benefice', 'rentabilite'])) {
      final a = d.agg(where: where, region: region);
      return 'Marge ${per.label} ($scope) : ${fmtM(a.marge)}, '
          'soit un taux de marge de ${fmtPct(a.margePct)}.';
    }

    final isCa = has(['chiffre', 'affaires', 'vente', 'revenu']) ||
        q == 'ca' ||
        q.startsWith('ca ') ||
        q.contains(' ca ') ||
        q.endsWith(' ca');
    if (isCa || region != null) {
      final a = d.agg(where: where, region: region);
      if (a.ca == 0) return 'Aucune vente ${per.label} ($scope).';
      return 'Chiffre d\'affaires ${per.label} ($scope) : ${fmtM(a.ca)}.\n'
          'Marge ${fmtM(a.marge)} (${fmtPct(a.margePct)}), panier moyen ${fmtInt(a.panier)}.';
    }

    return 'Je n\'ai pas compris cette question. Essayez par exemple : '
        '« chiffre d\'affaires en 2026 », « meilleure région » ou « alertes ».';
  }
}
