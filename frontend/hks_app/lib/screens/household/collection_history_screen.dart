import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CollectionHistoryScreen extends StatefulWidget {
  const CollectionHistoryScreen({super.key});
  @override
  State<CollectionHistoryScreen> createState() => _CollectionHistoryScreenState();
}

class _CollectionHistoryScreenState extends State<CollectionHistoryScreen> {
  final _api = ApiService();
  List<dynamic> _collections = [];
  bool _loading = true;
  String? _selectedMonth;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final h = await _api.getHouseholdMe();
      final cols = await _api.getCollections(householdId: h['id'] as int);
      if (mounted) setState(() { _collections = cols; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  List<dynamic> get _filtered {
    if (_selectedMonth == null) return _collections;
    return _collections.where((c) => c['date'].toString().startsWith(_selectedMonth!)).toList();
  }

  List<String> get _months {
    final seen = <String>{};
    final result = <String>[];
    for (final c in _collections) {
      final m = c['date'].toString().substring(0, 7);
      if (seen.add(m)) result.add(m);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.collectionHistory),
        actions: [const LangToggleButton(), const ThemeToggleButton(), const SizedBox(width: 8)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Month filter chips
                if (_months.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(children: [
                      _FilterChip(s.all, _selectedMonth == null, () => setState(() => _selectedMonth = null)),
                      ..._months.map((m) => _FilterChip(m, _selectedMonth == m, () => setState(() => _selectedMonth = m))),
                    ]),
                  ),
                // Summary bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _MiniStat(s.collectionsCount, '${_filtered.length}'),
                    _MiniStat(s.wasteCollected,
                        '${_filtered.fold(0.0, (s, c) => s + (double.tryParse(c['weight']?.toString() ?? '0') ?? 0.0)).toStringAsFixed(1)}kg'),
                    _MiniStat(s.paid,
                        'Rs ${_filtered.where((c) => c['payment_status'] == 'paid').fold(0.0, (s, c) => s + (double.tryParse(c['amount']?.toString() ?? '0') ?? 0.0)).toStringAsFixed(0)}'),
                  ]),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(child: Text(s.noData, style: GoogleFonts.poppins(color: AppTheme.textLight)))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (ctx, i) => _CollectionCard(
                              collection: _filtered[i],
                              s: s,
                              onRate: () async {
                                await context.push('/household/feedback',
                                    extra: Map<String, dynamic>.from(_filtered[i]));
                                _load(); // refresh after rating
                              },
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────
class _CollectionCard extends StatelessWidget {
  final Map<String, dynamic> collection;
  final AppStrings s;
  final VoidCallback onRate;

  const _CollectionCard({required this.collection, required this.s, required this.onRate});

  @override
  Widget build(BuildContext context) {
    final c = collection;
    final isRated = c['worker_rating'] != null;
    final rating = c['worker_rating'] as int?;
    final ratingColor = (rating != null && rating >= 1 && rating <= 4)
        ? AppStrings.ratingColors[rating - 1]
        : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
          child: const Icon(Icons.recycling, color: AppTheme.primary, size: 22),
        ),
        title: Text(
          '${(c['waste_type'] as String? ?? '').toUpperCase()} • ${c['weight']}kg',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(c['date'].toString(),
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('Rs ${c['amount']}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: c['payment_status'] == 'paid' ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(c['payment_status'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 9,
                      color: c['payment_status'] == 'paid' ? Colors.green.shade700 : Colors.red.shade700)),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Divider(),
              _Row('Worker', c['worker']?['worker_id'] ?? '-'),
              _Row(s.wasteType, (c['waste_type'] as String? ?? '').toUpperCase()),
              _Row(s.weight, '${c['weight']} kg'),
              _Row(s.rate2, 'Rs ${c['rate']}/kg'),
              _Row(s.totalAmount, 'Rs ${c['amount']}'),
              _Row(s.paymentMethod, (c['payment_method'] as String? ?? '').toUpperCase()),
              if (c['notes'] != null && c['notes'].toString().isNotEmpty)
                _Row(s.notes, c['notes'].toString()),
              const SizedBox(height: 10),
              const Divider(),

              // ── Feedback section ──
              Text(s.rateWorker,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              if (isRated) ...[
                // Show existing rating
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ratingColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ratingColor),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.star_rounded, color: ratingColor, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating != null && rating >= 1 && rating <= 4
                            ? s.ratingLabels[rating - 1]
                            : '$rating/4',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: ratingColor),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  if ((c['worker_feedback'] ?? '').toString().isNotEmpty)
                    Expanded(
                      child: Text('"${c['worker_feedback']}"',
                          style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight, fontStyle: FontStyle.italic),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                ]),
              ] else ...[
                // Rate button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRate,
                    icon: const Icon(Icons.star_outline_rounded, size: 18),
                    label: Text(s.rateWorker),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
      Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(this.label, this.selected, this.onTap);
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? AppTheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: selected ? AppTheme.primary : Colors.grey.shade300),
      ),
      child: Text(label, style: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.w500,
          color: selected ? Colors.white : AppTheme.textDark)),
    ),
  );
}

class _MiniStat extends StatelessWidget {
  final String label, value;
  const _MiniStat(this.label, this.value);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primary)),
    Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textLight)),
  ]);
}
