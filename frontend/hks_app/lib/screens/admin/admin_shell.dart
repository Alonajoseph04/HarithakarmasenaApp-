import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_theme.dart';

class AdminShell extends StatefulWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final tabs = [
      (path: '/admin', label: s.tabDashboard, icon: Icons.dashboard),
      (path: '/admin/workers', label: s.tabWorkers, icon: Icons.people),
      (path: '/admin/households', label: s.tabHouses, icon: Icons.home_work),
      (path: '/admin/wards', label: s.tabWards, icon: Icons.map),
      (path: '/admin/reports', label: s.tabReports, icon: Icons.bar_chart),
    ];
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          context.go(tabs[i].path);
        },
        items: tabs.map((t) => BottomNavigationBarItem(
          icon: Icon(t.icon), label: t.label,
        )).toList(),
      ),
    );
  }
}
