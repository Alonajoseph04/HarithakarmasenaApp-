import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _api = ApiService();
  List<dynamic> _notifications = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final n = await _api.getNotifications();
      if (mounted) setState(() { _notifications = n; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load notifications: ${e.toString().split("\n").first}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'collection': return Icons.recycling;
      case 'payment': return Icons.payments;
      case 'reminder': return Icons.skip_next_rounded;   // skip collection
      case 'broadcast': return Icons.broadcast_on_personal;
      case 'pickup': return Icons.add_box_rounded;        // extra pickup
      case 'feedback': return Icons.star_rounded;         // worker rating
      default: return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'collection': return AppTheme.primary;
      case 'payment': return Colors.orange;
      case 'reminder': return Colors.deepOrange;  // skip collection
      case 'broadcast': return Colors.purple;
      case 'pickup': return Colors.teal;          // extra pickup
      case 'feedback': return Colors.amber;       // worker rating
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => n['is_read'] == false))
            TextButton(
              onPressed: () async {
                await _api.markAllRead();
                _load();
              },
              child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('No notifications yet',
                          style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textLight)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _notifications.length,
                    itemBuilder: (ctx, i) {
                      final n = _notifications[i];
                      final isRead = n['is_read'] == true;
                      final type = n['notification_type'] as String? ?? 'general';
                      final color = _colorForType(type);

                      return Dismissible(
                        key: Key(n['id'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.done_all, color: Colors.red),
                        ),
                        onDismissed: (_) async {
                          await _api.markRead(n['id'] as int);
                          setState(() => _notifications.removeAt(i));
                        },
                        child: GestureDetector(
                          onTap: () async {
                            if (!isRead) {
                              await _api.markRead(n['id'] as int);
                              setState(() => _notifications[i]['is_read'] = true);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isRead ? Colors.white : color.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isRead ? Colors.grey.shade200 : color.withOpacity(0.3),
                                width: isRead ? 1 : 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_iconForType(type), color: color, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(n['title'] ?? '',
                                                style: GoogleFonts.poppins(
                                                    fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                                    fontSize: 13, color: AppTheme.textDark),
                                                maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ),
                                          if (!isRead)
                                            Container(
                                              width: 8, height: 8,
                                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(n['message'] ?? '',
                                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight),
                                          maxLines: 3, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 6),
                                      Text(
                                        n['created_at']?.toString().substring(0, 16).replaceAll('T', ' ') ?? '',
                                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
