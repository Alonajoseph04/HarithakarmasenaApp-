import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class WorkerShell extends StatefulWidget {
  final Widget child;
  const WorkerShell({super.key, required this.child});
  @override State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  int _idx = 0;
  int _unreadCount = 0;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchUnread();
  }

  Future<void> _fetchUnread() async {
    try {
      final count = await _api.getUnreadCount();
      if (mounted) setState(() => _unreadCount = count);
    } catch (_) {}
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
        onTap: (i) {
          setState(() => _idx = i);
          context.go(tabs[i].path);
          // Refresh unread count when navigating (especially to/from notifications)
          _fetchUnread();
        },
        items: tabs.asMap().entries.map((entry) {
          final i = entry.key;
          final t = entry.value;
          // Show badge on Alerts tab (index 4)
          if (i == 4 && _unreadCount > 0) {
            return BottomNavigationBarItem(
              icon: Badge(
                label: Text('$_unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
                backgroundColor: Colors.red,
                child: Icon(t.icon),
              ),
              label: t.label,
            );
          }
          return BottomNavigationBarItem(icon: Icon(t.icon), label: t.label);
        }).toList(),
      ),
    );
  }
}
