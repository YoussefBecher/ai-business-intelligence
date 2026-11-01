import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fmt.dart';

const double _kLeft = 46, _kRight = 10, _kTop = 8, _kBottom = 24;

/// Courbe du CA : série réelle, prévision en pointillés et intervalle de confiance.
/// Toucher ou faire glisser le doigt affiche la valeur du point le plus proche.
class SeriesChart extends StatefulWidget {
  final List<String> labels;
  final List<double?> real, fc, lo, hi;
  final double height;

  const SeriesChart({
    super.key,
    required this.labels,
    required this.real,
    this.fc = const [],
    this.lo = const [],
    this.hi = const [],
    this.height = 240,
  });

  @override
  State<SeriesChart> createState() => _SeriesChartState();
}

class _SeriesChartState extends State<SeriesChart> {
  int? sel;

  void _pick(double dx, double w) {
    final n = widget.labels.length;
    if (n < 2) return;
    final i = (((dx - _kLeft) / (w - _kLeft - _kRight)) * (n - 1)).round().clamp(0, n - 1);
    setState(() => sel = i);
  }

  double? _at(List<double?> l, int i) => i < l.length ? l[i] : null;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    var info = 'Touchez la courbe pour lire une valeur';
    final i = sel;
    if (i != null && i < widget.labels.length) {
      final r = _at(widget.real, i);
      final f = _at(widget.fc, i);
      final isFc = f != null && (r == null || widget.real.length > i && widget.real[i] == null);
      if (r != null && !isFc) {
        info = '${widget.labels[i]} : ${fmtInt(r)}';
      } else if (f != null) {
        final lo = _at(widget.lo, i), hi = _at(widget.hi, i);
        info = '${widget.labels[i]} (prévision) : ${fmtInt(f)}';
        if (lo != null && hi != null) info += '  [${fmtInt(lo)} à ${fmtInt(hi)}]';
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(info, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12.5)),
        const SizedBox(height: 6),
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, bc) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _pick(d.localPosition.dx, bc.maxWidth),
              onHorizontalDragUpdate: (d) => _pick(d.localPosition.dx, bc.maxWidth),
              child: CustomPaint(
                size: Size(bc.maxWidth, widget.height),
                painter: _ChartPainter(
                  labels: widget.labels,
                  real: widget.real,
                  fc: widget.fc,
                  lo: widget.lo,
                  hi: widget.hi,
                  sel: sel,
                  line: cs.primary,
                  fcColor: const Color(0xFFD9822B),
                  grid: cs.outlineVariant,
                  text: cs.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double?> real, fc, lo, hi;
  final int? sel;
  final Color line, fcColor, grid, text;

  _ChartPainter({
    required this.labels,
    required this.real,
    required this.fc,
    required this.lo,
    required this.hi,
    required this.sel,
    required this.line,
    required this.fcColor,
    required this.grid,
    required this.text,
  });

  double _niceStep(double raw) {
    if (raw <= 0) return 1;
    final p = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    for (final m in [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (m * p >= raw) return m * p;
    }
    return 10 * p;
  }

  void _text(Canvas c, String s, Offset o, {bool right = false, bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: text, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    var dx = o.dx;
    if (right) dx -= tp.width;
    if (center) dx -= tp.width / 2;
    tp.paint(c, Offset(dx, o.dy));
  }

  void _dashed(Canvas c, Path p, Paint paint) {
    for (final m in p.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        c.drawPath(m.extractPath(d, math.min(d + 6, m.length)), paint);
        d += 10;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = labels.length;
    if (n < 2) return;
    final vals = <double>[];
    for (final l in [real, fc, lo, hi]) {
      for (final v in l) {
        if (v != null) vals.add(v);
      }
    }
    if (vals.isEmpty) return;
    var mn = vals.reduce(math.min), mx = vals.reduce(math.max);
    final step = _niceStep((mx - mn) / 4);
    mn = (mn / step).floorToDouble() * step;
    mx = (mx / step).ceilToDouble() * step;
    if (mx == mn) mx = mn + step;

    final w = size.width - _kLeft - _kRight;
    final h = size.height - _kTop - _kBottom;
    double x(int i) => _kLeft + w * i / (n - 1);
    double y(double v) => _kTop + h * (1 - (v - mn) / (mx - mn));

    final gp = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var t = mn; t <= mx + step / 2; t += step) {
      canvas.drawLine(Offset(_kLeft, y(t)), Offset(size.width - _kRight, y(t)), gp);
      _text(canvas, '${fmtInt(t / 1000)} k', Offset(_kLeft - 6, y(t) - 6), right: true);
    }

    final every = math.max(1, (60 / (w / (n - 1))).ceil());
    for (var i = 0; i < n; i += every) {
      _text(canvas, labels[i], Offset(x(i), size.height - _kBottom + 6), center: true);
    }

    // Intervalle de confiance
    final idx = <int>[
      for (var i = 0; i < n; i++)
        if (i < hi.length && i < lo.length && hi[i] != null && lo[i] != null) i
    ];
    if (idx.length > 1) {
      final band = Path()..moveTo(x(idx.first), y(hi[idx.first]!));
      for (final i in idx.skip(1)) {
        band.lineTo(x(i), y(hi[i]!));
      }
      for (final i in idx.reversed) {
        band.lineTo(x(i), y(lo[i]!));
      }
      band.close();
      canvas.drawPath(band, Paint()..color = fcColor.withAlpha(40));
    }

    Path pathOf(List<double?> l) {
      final p = Path();
      var started = false;
      for (var i = 0; i < n && i < l.length; i++) {
        final v = l[i];
        if (v == null) continue;
        if (!started) {
          p.moveTo(x(i), y(v));
          started = true;
        } else {
          p.lineTo(x(i), y(v));
        }
      }
      return p;
    }

    if (fc.isNotEmpty) {
      _dashed(
        canvas,
        pathOf(fc),
        Paint()
          ..color = fcColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.drawPath(
      pathOf(real),
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );

    final i = sel;
    if (i != null && i < n) {
      canvas.drawLine(
        Offset(x(i), _kTop),
        Offset(x(i), _kTop + h),
        Paint()
          ..color = text
          ..strokeWidth = 1,
      );
      final r = i < real.length ? real[i] : null;
      final f = i < fc.length ? fc[i] : null;
      final v = r ?? f;
      if (v != null) {
        canvas.drawCircle(Offset(x(i), y(v)), 4.5, Paint()..color = r != null ? line : fcColor);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}
