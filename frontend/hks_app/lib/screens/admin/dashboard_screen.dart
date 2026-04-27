import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await _api.getAdminSummary();
      setState(() { _summary = s; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('HKS Admin Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined),
              onPressed: () => context.go('/admin/notifications')),
          IconButton(icon: const Icon(Icons.broadcast_on_personal),
              onPressed: () => context.go('/admin/broadcast')),
          IconButton(icon: const Icon(Icons.logout),
              onPressed: () async {
                await auth.logout();
                if (mounted) context.go('/');
              }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats grid
                  GridView.count(
                    crossAxisCount: 2, shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12, crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      _StatCard('Workers', '${_summary?['total_workers'] ?? 0}',
                          Icons.people, Colors.blue),
                      _StatCard('Households', '${_summary?['total_households'] ?? 0}',
                          Icons.home_work, Colors.orange),
                      _StatCard('Total Waste', '${(_summary?['total_weight'] ?? 0.0).toStringAsFixed(1)} kg',
                          Icons.recycling, AppTheme.primary),
                      _StatCard('Revenue', 'Rs ${(_summary?['total_amount'] ?? 0.0).toStringAsFixed(0)}',
                          Icons.currency_rupee, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Monthly bar chart
                  if (_summary?['monthly_data'] != null) ...[
                    const _SectionHeader('Monthly Collections (last 6 months)'),
                    const SizedBox(height: 12),
                    Container(
                      height: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10)],
                      ),
                      child: _MonthlyBarChart(data: List<Map<String, dynamic>>.from(_summary!['monthly_data'])),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const _SectionHeader('Quick Actions'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _QuickAction(icon: Icons.person_add, label: 'Add Worker',
                        color: Colors.blue, onTap: () => context.go('/admin/workers'))),
                    const SizedBox(width: 12),
                    Expanded(child: _QuickAction(icon: Icons.home_work, label: 'Add House',
                        color: Colors.orange, onTap: () => context.go('/admin/households'))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _QuickAction(icon: Icons.bar_chart, label: 'Reports',
                        color: AppTheme.primary, onTap: () => context.go('/admin/reports'))),
                    const SizedBox(width: 12),
                    Expanded(child: _QuickAction(icon: Icons.broadcast_on_personal, label: 'Broadcast',
                        color: Colors.purple, onTap: () => context.go('/admin/broadcast'))),
                  ]),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              Text(title, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark));
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _MonthlyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('No data'));
    final maxVal = data.map((d) => (double.tryParse(d['amount']?.toString() ?? '0') ?? 0.0)).fold(0.0, (a, b) => a > b ? a : b);
    return BarChart(
      BarChartData(
        maxY: maxVal * 1.2 + 100,
        barGroups: data.asMap().entries.map((e) {
          return BarChartGroupData(x: e.key, barRods: [
            BarChartRodData(
                toY: (double.tryParse(e.value['amount']?.toString() ?? '0') ?? 0.0),
                color: AppTheme.primary,
                width: 18,
                borderRadius: BorderRadius.circular(6)),
          ]);
        }).toList(),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (val, meta) {
              final idx = val.toInt();
              if (idx >= 0 && idx < data.length) {
                final m = data[idx]['month'].toString();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(m.substring(0, 3), style: GoogleFonts.poppins(fontSize: 9)),
                );
              }
              return const SizedBox();
            },
          )),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (val) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
