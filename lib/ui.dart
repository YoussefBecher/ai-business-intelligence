import 'package:flutter/material.dart';

/// Couleur de fond des panneaux : blanc en thème clair, gris foncé en thème sombre.
Color panelColorOf(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return Theme.of(context).brightness == Brightness.dark ? cs.surfaceContainerLow : Colors.white;
}

/// Décoration commune des panneaux et des cartes KPI : fond uni, coins arrondis, contour fin.
BoxDecoration panelDecoration(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: panelColorOf(context),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: cs.outlineVariant.withAlpha(150)),
  );
}

/// Titre de page avec un sous-titre discret.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const PageHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

/// Section de page : fond uni, contour fin, titre et sous-titre facultatifs.
class Panel extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const Panel({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: panelDecoration(context),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(title!, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
          ],
          if (title != null || subtitle != null) const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
