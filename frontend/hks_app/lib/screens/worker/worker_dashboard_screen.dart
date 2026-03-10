import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});
  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabCtrl;
  final _periods = ['today', 'week', 'month', 'year'];
  Map<String, dynamic>? _stats;
  bool _loading = true;
  int _selectedIdx = 2; // default: month

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this, initialIndex: _selectedIdx);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        setState(() => _selectedIdx = _tabCtrl.index);
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final worker = await _api.getWorkerMe();
      final stats = await _api.getStats(
          period: _periods[_selectedIdx], workerId: worker['id'] as int);
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final periodLabels = [s.today, s.week, s.month, s.year];

    return Scaffold(
      appBar: AppBar(
        title: Text(s.performance),
        actions: [const LangToggleButton(), const ThemeToggleButton(), const SizedBox(width: 8)],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: periodLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── 4 stat cards in 2×2 grid ────────────────────
                  Row(children: [
                    Expanded(child: _StatCard(
                      s.visited,
                      '${_stats?['households_visited'] ?? 0}',
                      Icons.home_work_rounded, Colors.blue,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(
                      s.collectionsCount,
                      '${_stats?['total_collections'] ?? 0}',
                      Icons.list_alt_rounded, AppTheme.primary,
                    )),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _StatCard(
                      s.wasteCollected,
                      '${(_stats?['total_weight'] ?? 0.0).toStringAsFixed(1)}kg',
                      Icons.recycling_rounded, Colors.teal,
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _StatCard(
                      s.revenueGenerated,
                      'Rs ${(_stats?['total_amount'] ?? 0.0).toStringAsFixed(0)}',
                      Icons.currency_rupee_rounded, Colors.orange,
                    )),
                  ]),

                  // ── Average rating ───────────────────────────────
                  if ((_stats?['avg_rating'] ?? 0.0) > 0) ...[
                    const SizedBox(height: 10),
                    _RatingBar(rating: (_stats!['avg_rating'] as num).toDouble(), s: s),
                  ],

                  const SizedBox(height: 20),

                  // ── Waste breakdown chart ────────────────────────
                  if (_stats?['waste_breakdown'] != null &&
                      (_stats!['waste_breakdown'] as List).isNotEmpty) ...[
                    Text(s.wasteBreakdown,
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Container(
                      height: 220,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ?? Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
                      ),
                      child: _WasteBreakdownChart(
                        breakdown: List<Map<String, dynamic>>.from(_stats!['waste_breakdown']),
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color ?? Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(children: [
                          const Icon(Icons.inbox_rounded, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(s.noData, style: GoogleFonts.poppins(color: AppTheme.textLight)),
                        ]),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withValues(alpha: 0.25)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 8),
      Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight)),
    ]),
  );
}

class _RatingBar extends StatelessWidget {
  final double rating;
  final AppStrings s;
  const _RatingBar({required this.rating, required this.s});

  @override
  Widget build(BuildContext context) {
    // rating is 1–4
    final idx = (rating.round() - 1).clamp(0, 3);
    final color = AppStrings.ratingColors[idx];
    final label = s.ratingLabels[idx];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(Icons.star_rounded, color: color, size: 28),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.avgRating,
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight)),
          Text('${rating.toStringAsFixed(1)} / 4 — $label',
              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ]),
      ]),
    );
  }
}

class _WasteBreakdownChart extends StatelessWidget {
  final List<Map<String, dynamic>> breakdown;
  const _WasteBreakdownChart({required this.breakdown});

  static const _colors = [
    AppTheme.primary, Colors.blue, Colors.orange,
    Colors.purple, Colors.teal, Colors.red, Colors.pink
  ];

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: PieChart(PieChartData(
          sections: breakdown.asMap().entries.map((e) {
            final color = _colors[e.key % _colors.length];
            final wt = e.value['waste_type']?.toString() ?? '';
            return PieChartSectionData(
              value: (e.value['count'] as int).toDouble(),
              color: color,
              title: wt.length >= 2 ? wt.substring(0, 2).toUpperCase() : wt.toUpperCase(),
              titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              radius: 65,
            );
          }).toList(),
          centerSpaceRadius: 30,
        )),
      ),
      const SizedBox(width: 12),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: breakdown.asMap().entries.map((e) {
          final color = _colors[e.key % _colors.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text('${e.value['waste_type']} (${e.value['count']})',
                  style: GoogleFonts.poppins(fontSize: 11)),
            ]),
          );
        }).toList(),
      ),
    ]);
  }
}
