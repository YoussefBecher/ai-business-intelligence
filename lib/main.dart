import 'package:flutter/material.dart';

import 'alerts_page.dart';
import 'assistant_page.dart';
import 'dashboard_page.dart';
import 'data.dart';
import 'forecast_page.dart';

void main() => runApp(const BiApp());

class BiApp extends StatelessWidget {
  const BiApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0B6E63);
    return MaterialApp(
      title: 'AI Business Intelligence',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF1F5F4),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          indicatorColor: Color(0xFFCDE8E3),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
      ),
      themeMode: ThemeMode.system,
      home: const _Loader(),
    );
  }
}

class _Loader extends StatefulWidget {
  const _Loader();

  @override
  State<_Loader> createState() => _LoaderState();
}

class _LoaderState extends State<_Loader> {
  late final Future<SalesData> future = SalesData.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SalesData>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(body: Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Impossible de charger les données : ${snap.error}'),
          )));
        }
        if (!snap.hasData) {
          return const _Splash();
        }
        return _Shell(data: snap.data!);
      },
    );
  }
}

/// Écran de démarrage : logo, nom de l'application et indicateur de chargement.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.insights, size: 40, color: cs.onPrimary),
            ),
            const SizedBox(height: 18),
            const Text('AI Business Intelligence',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
            const SizedBox(height: 4),
            Text('Assistant décisionnel', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
            const SizedBox(height: 26),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _Shell extends StatefulWidget {
  final SalesData data;
  const _Shell({required this.data});

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pages = <Widget>[
      DashboardPage(data: widget.data),
      ForecastPage(data: widget.data),
      AlertsPage(data: widget.data),
      AssistantPage(data: widget.data),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                const _TopBar(),
                Expanded(child: IndexedStack(index: index, children: pages)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: cs.outlineVariant.withAlpha(150))),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Tableau'),
            NavigationDestination(icon: Icon(Icons.show_chart), label: 'Prévisions'),
            NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alertes'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Assistant'),
          ],
        ),
      ),
    );
  }
}

/// Barre de marque affichée en haut de tous les écrans.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.insights, size: 20, color: cs.onPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI Business Intelligence',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                Text('Assistant décisionnel',
                    style: TextStyle(fontSize: 11.5, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
