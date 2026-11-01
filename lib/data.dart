import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'fmt.dart';

class Product {
  final String name, category, sub;
  const Product(this.name, this.category, this.sub);
}

/// Prévision d'un mois : valeur centrale, borne basse, borne haute.
class Fc {
  final double mid, lo, hi;
  const Fc(this.mid, this.lo, this.hi);
}

/// Une ligne de vente : mois (index), région, produit, CA, marge, commande, jour du mois.
class SaleRow {
  final int m, r, p, o, d;
  final double ca, marge;
  const SaleRow({
    required this.m,
    required this.r,
    required this.p,
    required this.ca,
    required this.marge,
    required this.o,
    required this.d,
  });
}

/// Agrégat de ventes sur un périmètre (période et région).
class Agg {
  double ca = 0, marge = 0, obj = 0;
  final Set<int> orders = {};
  int get nOrders => orders.length;
  double get margePct => ca == 0 ? 0 : marge / ca;
  double get panier => nOrders == 0 ? 0 : ca / nOrders;

  /// Taux de réalisation de l'objectif, null s'il n'y a pas d'objectif.
  double? get real => obj == 0 ? null : ca / obj;
}

class ProductStat {
  final int i;
  double ca = 0, marge = 0;
  ProductStat(this.i);
  double get margePct => ca == 0 ? 0 : marge / ca;
}

class SalesData {
  final List<String> months; // 'AAAA-MM'
  final List<String> regions;
  final List<Product> products;
  final List<SaleRow> rows;
  final List<List<double>> obj; // [mois, région, objectif]
  final List<Fc> forecast;

  SalesData({
    required this.months,
    required this.regions,
    required this.products,
    required this.rows,
    required this.obj,
    required this.forecast,
  });

  static Future<SalesData> load() async {
    final txt = await rootBundle.loadString('assets/data.json');
    final j = jsonDecode(txt) as Map<String, dynamic>;
    return SalesData(
      months: (j['months'] as List).cast<String>(),
      regions: (j['regions'] as List).cast<String>(),
      products: (j['products'] as List).map((e) {
        final l = (e as List).cast<String>();
        return Product(l[0], l[1], l[2]);
      }).toList(),
      rows: (j['rows'] as List).map((e) {
        final l = e as List;
        return SaleRow(
          m: l[0] as int,
          r: l[1] as int,
          p: l[2] as int,
          ca: (l[3] as num).toDouble(),
          marge: (l[4] as num).toDouble(),
          o: l[5] as int,
          d: l[6] as int,
        );
      }).toList(),
      obj: (j['obj'] as List)
          .map((e) => (e as List).map((x) => (x as num).toDouble()).toList())
          .toList(),
      forecast: (j['forecast'] as List).map((e) {
        final l = (e as List).map((x) => (x as num).toDouble()).toList();
        return Fc(l[0], l[1], l[2]);
      }).toList(),
    );
  }

  int get lastMonth => months.length - 1;
  int yearOf(int m) => int.parse(months[m].substring(0, 4));
  int monthOf(int m) => int.parse(months[m].substring(5, 7));

  String monthShort(int m) =>
      '${monthShortNames[monthOf(m) - 1]} ${months[m].substring(2, 4)}';
  String monthLong(int m) => '${monthShortNames[monthOf(m) - 1]} ${yearOf(m)}';

  /// Libellé du k-ième mois prévu (0 = mois qui suit l'historique).
  String forecastShort(int k) {
    final m0 = monthOf(lastMonth);
    final y = yearOf(lastMonth) + (m0 + k) ~/ 12;
    final mo = (m0 + k) % 12;
    return '${monthShortNames[mo]} ${y % 100}';
  }

  String forecastLong(int k) {
    final m0 = monthOf(lastMonth);
    final y = yearOf(lastMonth) + (m0 + k) ~/ 12;
    final mo = (m0 + k) % 12;
    return '${monthShortNames[mo]} $y';
  }

  Agg agg({bool Function(int m)? where, int? region}) {
    final a = Agg();
    for (final x in rows) {
      if (region != null && x.r != region) continue;
      if (where != null && !where(x.m)) continue;
      a.ca += x.ca;
      a.marge += x.marge;
      a.orders.add(x.o);
    }
    for (final o in obj) {
      final m = o[0].toInt(), r = o[1].toInt();
      if (region != null && r != region) continue;
      if (where != null && !where(m)) continue;
      a.obj += o[2];
    }
    return a;
  }

  List<double> monthlyCa({int? region}) {
    final out = List<double>.filled(months.length, 0);
    for (final x in rows) {
      if (region != null && x.r != region) continue;
      out[x.m] += x.ca;
    }
    return out;
  }

  List<ProductStat> productStats({bool Function(int m)? where, int? region}) {
    final stats = List<ProductStat>.generate(products.length, (i) => ProductStat(i));
    for (final x in rows) {
      if (region != null && x.r != region) continue;
      if (where != null && !where(x.m)) continue;
      stats[x.p].ca += x.ca;
      stats[x.p].marge += x.marge;
    }
    return stats.where((s) => s.ca > 0).toList();
  }
}
