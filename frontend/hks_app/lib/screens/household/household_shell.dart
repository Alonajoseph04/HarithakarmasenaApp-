import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_theme.dart';

class HouseholdShell extends StatefulWidget {
  final Widget child;
  const HouseholdShell({super.key, required this.child});
  @override
  State<HouseholdShell> createState() => _HouseholdShellState();
}

class _HouseholdShellState extends State<HouseholdShell> {
  int _idx = 0;

  List<({String path, String label, IconData icon})> _tabs(AppStrings s) => [
    (path: '/household', label: isMl(context) ? 'ഹോം' : 'Home', icon: Icons.home),
    (path: '/household/history', label: isMl(context) ? 'ചരിത്രം' : 'History', icon: Icons.history),
    (path: '/household/payments', label: isMl(context) ? 'പേയ്‌മെന്റ്' : 'Payments', icon: Icons.payments),
    (path: '/household/insights', label: isMl(context) ? 'വിശകലനം' : 'Insights', icon: Icons.bar_chart),
    (path: '/household/notifications', label: isMl(context) ? 'അറിയിപ്പ്' : 'Alerts', icon: Icons.notifications),
  ];

  bool isMl(BuildContext ctx) {
    try { return ctx.read<LanguageProvider>().isMalayalam; } catch (_) { return false; }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final tabs = _tabs(lang.strings);
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) { setState(() => _idx = i); context.go(tabs[i].path); },
        items: tabs.map((t) => BottomNavigationBarItem(icon: Icon(t.icon), label: t.label)).toList(),
      ),
    );
  }
}
