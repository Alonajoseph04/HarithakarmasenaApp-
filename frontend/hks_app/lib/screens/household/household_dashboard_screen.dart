import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class HouseholdDashboardScreen extends StatefulWidget {
  const HouseholdDashboardScreen({super.key});
  @override
  State<HouseholdDashboardScreen> createState() => _HouseholdDashboardScreenState();
}

class _HouseholdDashboardScreenState extends State<HouseholdDashboardScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _household;
  List<dynamic> _recentCollections = [];
  int _unreadCount = 0;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final h = await _api.getHouseholdMe();
      final cols = await _api.getCollections(householdId: h['id'] as int);
      final unread = await _api.getUnreadCount();
      setState(() {
        _household = h;
        _recentCollections = cols.take(5).toList();
        _unreadCount = unread;
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.myDashboard),
        actions: [
          const LangToggleButton(),
          const ThemeToggleButton(),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.go('/household/notifications'),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    width: 18, height: 18,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: Center(child: Text('$_unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async { await auth.logout(); if (mounted) context.go('/'); },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight],
                          begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        const CircleAvatar(
                          radius: 28, backgroundColor: Colors.white30,
                          child: Icon(Icons.home, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_household?['name'] ?? '-',
                              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text(_household?['ward']?['name'] ?? '-',
                              style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
                          Text(_household?['address'] ?? '-',
                              style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60), maxLines: 2),
                        ])),
                      ]),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: _InfoChip(
                          label: s.lastCollection,
                          value: _household?['last_collection'] ?? 'Never',
                          icon: Icons.calendar_today,
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: _InfoChip(
                          label: s.pending,
                          value: 'Rs ${(double.tryParse(_household?['pending_amount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(0)}',
                          icon: Icons.currency_rupee,
                          highlight: (double.tryParse(_household?['pending_amount']?.toString() ?? '0') ?? 0.0) > 0,
                        )),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 20),

                  // Quick links
                  Text(s.quickAccess, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.0,
                    children: [
                      _QuickCard(s.collectionHistory, Icons.history, Colors.blue, () => context.go('/household/history')),
                      _QuickCard(s.paymentHistory, Icons.receipt_long, Colors.orange, () => context.go('/household/payments')),
                      _QuickCard(s.wasteInsights, Icons.bar_chart, AppTheme.primary, () => context.go('/household/insights')),
                      _QuickCard(s.notifications, Icons.notifications, Colors.purple, () => context.go('/household/notifications')),
                      _QuickCard(s.wasteGuidelines, Icons.eco, Colors.green, () => context.go('/household/guidelines')),
                      _QuickCard(s.contactWorker, Icons.phone, Colors.teal, () => context.go('/household/worker-contact')),
                      _QuickCard(s.skipCollection, Icons.skip_next, Colors.orange.shade700, () => context.go('/household/skip')),
                    ],
                  ),
                  const SizedBox(height: 20),

                   // Recent collections
                  if (_recentCollections.isNotEmpty) ...[
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(s.recentCollections, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                      TextButton.icon(
                        icon: const Icon(Icons.history, size: 16),
                        label: Text(s.seeAll),
                        onPressed: () => context.go('/household/history'),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    ..._recentCollections.map((c) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: const Icon(Icons.recycling, color: AppTheme.primary, size: 22),
                        ),
                        title: Text('${c['waste_type']?.toString().toUpperCase()} • ${c['weight']}kg',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                        subtitle: Text('${c['date']} • ${c['payment_method']?.toString().toUpperCase()}',
                            style: GoogleFonts.poppins(fontSize: 12)),
                        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('Rs ${c['amount']}',
                              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
                          if (c['worker_rating'] != null)
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.star, color: Colors.amber, size: 12),
                              Text(' ${c['worker_rating']}/4', style: GoogleFonts.poppins(fontSize: 10, color: Colors.amber.shade700)),
                            ])
                          else
                            TextButton(
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                              onPressed: () => context.push('/household/feedback', extra: Map<String, dynamic>.from(c)),
                              child: Text('Rate', style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                            ),
                        ]),
                      ),
                    )),
                  ],
                ],
              ),
            ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool highlight;
  const _InfoChip({required this.label, required this.value, required this.icon, this.highlight = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: highlight ? Colors.red.shade400 : Colors.white24,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(children: [
      Icon(icon, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white70)),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      ])),
    ]),
  );
}

class _QuickCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickCard(this.label, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color))),
      ]),
    ),
  );
}
