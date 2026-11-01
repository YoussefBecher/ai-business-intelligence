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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(useMaterial3: true, colorSchemeSeed: seed, brightness: Brightness.dark),
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return _Shell(data: snap.data!);
      },
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
    final pages = <Widget>[
      DashboardPage(data: widget.data),
      ForecastPage(data: widget.data),
      AlertsPage(data: widget.data),
      AssistantPage(data: widget.data),
    ];
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: IndexedStack(index: index, children: pages),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Tableau'),
          NavigationDestination(icon: Icon(Icons.show_chart), label: 'Prévisions'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Alertes'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Assistant'),
        ],
      ),
    );
  }
}
