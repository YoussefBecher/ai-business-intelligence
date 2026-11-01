// Formatage des nombres à la française, sans dépendance externe.

String fmtInt(num v) {
  final neg = v < 0;
  final s = v.abs().round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return (neg ? '-' : '') + b.toString();
}

/// 11571344 -> "11,57 M" ; 1994 -> "1 994"
String fmtM(double v) {
  if (v.abs() >= 1e6) {
    return '${(v / 1e6).toStringAsFixed(2).replaceAll('.', ',')} M';
  }
  return fmtInt(v);
}

/// 0.189 -> "18,9 %"
String fmtPct(double x, [int decimals = 1]) =>
    '${(x * 100).toStringAsFixed(decimals).replaceAll('.', ',')} %';

String fmtSigned(double x) =>
    '${x >= 0 ? '+' : ''}${(x * 100).toStringAsFixed(1).replaceAll('.', ',')} %';

const monthShortNames = [
  'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
  'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'
];
