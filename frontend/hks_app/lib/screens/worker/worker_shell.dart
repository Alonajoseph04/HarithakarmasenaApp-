import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_theme.dart';

class WorkerShell extends StatefulWidget {
  final Widget child;
  const WorkerShell({super.key, required this.child});
  @override State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  int _idx = 0;

  bool isMl(BuildContext ctx) {
    try { return ctx.read<LanguageProvider>().isMalayalam; } catch (_) { return false; }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final ml = lang.isMalayalam;
    final tabs = [
      (path: '/worker', label: ml ? 'ശേഖരണം' : 'Collection', icon: Icons.recycling),
      (path: '/worker/scan', label: ml ? 'QR സ്കാൻ' : 'Scan QR', icon: Icons.qr_code_scanner),
      (path: '/worker/extra-requests', label: ml ? 'അഭ്യർത്ഥനകൾ' : 'Requests', icon: Icons.inbox_rounded),
      (path: '/worker/stats', label: ml ? 'എന്റെ സ്കോർ' : 'My Stats', icon: Icons.bar_chart),
      (path: '/worker/notifications', label: ml ? 'അറിയിപ്പ്' : 'Alerts', icon: Icons.notifications),
    ];
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
