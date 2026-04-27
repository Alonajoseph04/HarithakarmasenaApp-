import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;

  // ── Collections tab state ──
  List<dynamic> _collections = [];
  List<dynamic> _workers = [];
  List<dynamic> _wards = [];
  bool _loading = true;
  String? _error;
  int? _selectedWardId;
  int? _selectedWorkerId;
  String _statusFilter = 'all'; // 'all' | 'paid' | 'pending'
  String? _selectedMonth; // 'yyyy-MM' e.g. '2026-03'

  // ── Worker Coverage tab state ──
  int? _covWardId;
  int? _covWorkerId;
  String _covStatus = 'all'; // 'all' | 'covered' | 'pending'
  bool _covLoading = false;
  Map<String, dynamic>? _coverageData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _api.getCollections(),
        _api.getWorkers(),
        _api.getWards(),
      ]);
      setState(() {
        _collections = results[0];
        _workers    = results[1];
        _wards      = results[2];
        _loading    = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  double _toDouble(dynamic val) => double.tryParse(val?.toString() ?? '0') ?? 0.0;

  /// Returns (yyyy-MM label, display label) for the last 12 months.
  List<({String value, String label})> get _monthOptions {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      return (
        value: '${d.year}-${d.month.toString().padLeft(2, '0')}',
        label: DateFormat('MMMM yyyy').format(d),
      );
    });
  }

  List<dynamic> get _filtered {
    return _collections.where((c) {
      if (_selectedWardId != null) {
        final wardId = c['household']?['ward']?['id'];
        if (wardId != _selectedWardId) return false;
      }
      if (_selectedWorkerId != null) {
        final workerId = c['worker']?['id'];
        if (workerId != _selectedWorkerId) return false;
      }
      if (_statusFilter != 'all') {
        if (c['payment_status'] != _statusFilter) return false;
      }
      if (_selectedMonth != null) {
        // c['date'] is 'yyyy-MM-dd'
        final dateStr = c['date']?.toString() ?? '';
        if (!dateStr.startsWith(_selectedMonth!)) return false;
      }
      return true;
    }).toList();
  }

  double get _totalAmount => _filtered.fold(0.0, (s, c) => s + _toDouble(c['amount']));
  double get _paidAmount  => _filtered.where((c) => c['payment_status'] == 'paid')
      .fold(0.0, (s, c) => s + _toDouble(c['amount']));
  double get _pendingAmount => _filtered.where((c) => c['payment_status'] == 'pending')
      .fold(0.0, (s, c) => s + _toDouble(c['amount']));

  // ── Worker coverage load ──
  Future<void> _loadCoverage() async {
    if (_covWardId == null) return;
    setState(() => _covLoading = true);
    try {
      final data = await _api.getWorkerCoverage(
        wardId: _covWardId!,
        workerId: _covWorkerId,
        status: _covStatus,
      );
      setState(() { _coverageData = data; _covLoading = false; });
    } catch (e) {
      setState(() => _covLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list_alt), text: 'Collections'),
            Tab(icon: Icon(Icons.home_work), text: 'Worker Coverage'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCollectionsTab(),
          _buildWorkerCoverageTab(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  TAB 1 — Collections
  // ════════════════════════════════════════════════════
  Widget _buildCollectionsTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 56, color: AppTheme.error),
          const SizedBox(height: 12),
          Text('Failed to load reports', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(_error!, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(icon: const Icon(Icons.refresh), label: const Text('Retry'), onPressed: _load),
        ]),
      ));
    }

    final filtered = _filtered;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Row 1: Ward + Worker filters ──
          Row(children: [
            Expanded(child: DropdownButtonFormField<int?>(
              initialValue: _selectedWardId,
              decoration: const InputDecoration(labelText: 'Ward', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Wards')),
                ..._wards.map((w) => DropdownMenuItem<int?>(value: w['id'] as int, child: Text(w['name'].toString(), overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) => setState(() { _selectedWardId = v; }),
            )),
            const SizedBox(width: 8),
            Expanded(child: DropdownButtonFormField<int?>(
              initialValue: _selectedWorkerId,
              decoration: const InputDecoration(labelText: 'Worker', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Workers')),
                ..._workers.map((w) => DropdownMenuItem<int?>(value: w['id'] as int, child: Text(w['worker_id'].toString()))),
              ],
              onChanged: (v) => setState(() { _selectedWorkerId = v; }),
            )),
          ]),
          const SizedBox(height: 8),

          // ── Row 2: Month filter ──
          DropdownButtonFormField<String?>(
            initialValue: _selectedMonth,
            decoration: const InputDecoration(
              labelText: 'Month',
              prefixIcon: Icon(Icons.calendar_month),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All Months')),
              ..._monthOptions.map((m) => DropdownMenuItem<String?>(
                value: m.value,
                child: Text(m.label),
              )),
            ],
            onChanged: (v) => setState(() => _selectedMonth = v),
          ),
          const SizedBox(height: 8),

          // ── Row 3: Status + clear filters ──
          Row(children: [
            Text('Status:', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
            const SizedBox(width: 8),
            ...['all', 'paid', 'pending'].map((s) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(s == 'all' ? 'All' : s == 'paid' ? 'Completed' : 'Pending'),
                selected: _statusFilter == s,
                onSelected: (_) => setState(() => _statusFilter = s),
                selectedColor: s == 'pending' ? Colors.orange : AppTheme.primary,
                labelStyle: TextStyle(
                  color: _statusFilter == s ? Colors.white : AppTheme.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )),
            const Spacer(),
            if (_selectedWardId != null || _selectedWorkerId != null ||
                _selectedMonth != null || _statusFilter != 'all')
              TextButton.icon(
                icon: const Icon(Icons.clear, size: 14),
                label: Text('Clear', style: GoogleFonts.poppins(fontSize: 12)),
                onPressed: () => setState(() {
                  _selectedWardId = null;
                  _selectedWorkerId = null;
                  _selectedMonth = null;
                  _statusFilter = 'all';
                }),
                style: TextButton.styleFrom(foregroundColor: Colors.red, padding: EdgeInsets.zero),
              ),
          ]),
          const SizedBox(height: 16),

          // Summary cards
          Row(children: [
            Expanded(child: _Card('Total', '${filtered.length}', Icons.list_alt, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _Card('Completed', '${filtered.where((c) => c['payment_status'] == 'paid').length}', Icons.check_circle, Colors.green)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Card('Pending', '${filtered.where((c) => c['payment_status'] == 'pending').length}', Icons.pending, Colors.orange)),
            const SizedBox(width: 10),
            Expanded(child: _Card('Collected', 'Rs ${_paidAmount.toStringAsFixed(0)}', Icons.payments, Colors.teal)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Card('Pending Amount', 'Rs ${_pendingAmount.toStringAsFixed(0)}', Icons.hourglass_bottom, Colors.red)),
            const SizedBox(width: 10),
            Expanded(child: _Card('Total Billed', 'Rs ${_totalAmount.toStringAsFixed(0)}', Icons.receipt, Colors.purple)),
          ]),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _selectedMonth != null
                      ? 'Collection Records — ${_monthOptions.firstWhere((m) => m.value == _selectedMonth).label}'
                      : 'Collection Records',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Text('${filtered.length} records', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
            ],
          ),
          const SizedBox(height: 10),

          if (filtered.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                const Icon(Icons.inbox, size: 48, color: Colors.grey),
                const SizedBox(height: 8),
                Text('No collections found for the selected filters.',
                    style: GoogleFonts.poppins(color: AppTheme.textLight), textAlign: TextAlign.center),
              ]),
            ))
          else
            ...filtered.map((c) => _CollectionCard(c: c, toDouble: _toDouble)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  //  TAB 2 — Worker Coverage
  // ════════════════════════════════════════════════════
  Widget _buildWorkerCoverageTab() {
    final households = (_coverageData?['households'] as List?) ?? [];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Controls
        Text('Filter Houses by Worker', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        DropdownButtonFormField<int?>(
          initialValue: _covWardId,
          decoration: const InputDecoration(labelText: 'Select Ward *', prefixIcon: Icon(Icons.location_city), isDense: true),
          items: [
            const DropdownMenuItem(value: null, child: Text('Choose Ward')),
            ..._wards.map((w) => DropdownMenuItem<int?>(value: w['id'] as int, child: Text(w['name'].toString()))),
          ],
          onChanged: (v) => setState(() { _covWardId = v; _coverageData = null; }),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<int?>(
          initialValue: _covWorkerId,
          decoration: const InputDecoration(labelText: 'Select Worker (optional)', prefixIcon: Icon(Icons.person), isDense: true),
          items: [
            const DropdownMenuItem(value: null, child: Text('All Workers')),
            ..._workers.map((w) => DropdownMenuItem<int?>(
              value: w['id'] as int,
              child: Text('${w['worker_id']} — ${w['user']?['first_name'] ?? ''} ${w['user']?['last_name'] ?? ''}'.trim()),
            )),
          ],
          onChanged: (v) => setState(() { _covWorkerId = v; _coverageData = null; }),
        ),
        const SizedBox(height: 10),

        // Status sort chips
        Row(children: [
          Text('Show:', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
          const SizedBox(width: 8),
          ...['all', 'covered', 'pending'].map((s) => Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(s == 'all' ? 'All Houses' : s == 'covered' ? 'Covered ✓' : 'Pending ⏳'),
              selected: _covStatus == s,
              onSelected: (_) => setState(() => _covStatus = s),
              selectedColor: s == 'covered' ? Colors.green : s == 'pending' ? Colors.orange : AppTheme.primary,
              labelStyle: TextStyle(
                color: _covStatus == s ? Colors.white : AppTheme.textDark,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          )),
        ]),
        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _covLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.search),
            label: Text(_covLoading ? 'Loading...' : 'Load Coverage'),
            onPressed: (_covWardId == null || _covLoading) ? null : _loadCoverage,
          ),
        ),
        const SizedBox(height: 20),

        // Coverage summary
        if (_coverageData != null) ...[
          Row(children: [
            Expanded(child: _Card('Total', '${_coverageData!['total']}', Icons.home, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _Card('Covered', '${_coverageData!['covered']}', Icons.check_circle, Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: _Card('Pending', '${_coverageData!['pending']}', Icons.pending, Colors.orange)),
          ]),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_coverageData!['total'] as int) > 0
                  ? (_coverageData!['covered'] as int) / (_coverageData!['total'] as int)
                  : 0,
              minHeight: 12,
              backgroundColor: Colors.orange.shade100,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_coverageData!['total'] as int) > 0 ? ((_coverageData!['covered'] as int) * 100 / (_coverageData!['total'] as int)).toStringAsFixed(0) : 0}% covered',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Household List', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
              Text('${households.length} houses', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
            ],
          ),
          const SizedBox(height: 8),

          if (households.isEmpty)
            Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Icon(Icons.inbox, size: 40, color: Colors.grey),
                Text('No households found.', style: GoogleFonts.poppins(color: AppTheme.textLight)),
              ]),
            ))
          else
            ...households.map<Widget>((hh) {
              final isCovered = hh['status'] == 'covered';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isCovered ? Colors.green.shade200 : Colors.orange.shade200, width: 1.5),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCovered ? Colors.green.shade50 : Colors.orange.shade50,
                    child: Icon(
                      isCovered ? Icons.check_circle : Icons.pending,
                      color: isCovered ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text(hh['name']?.toString() ?? '-',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    '${hh['address'] ?? '-'}  •  ${hh['phone'] ?? '-'}',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isCovered ? Colors.green.shade100 : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCovered ? 'COVERED' : 'PENDING',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isCovered ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Rs ${(hh['monthly_fee'] as double).toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            }),
        ],
      ],
    );
  }
}

// ── Shared helpers ──

class _CollectionCard extends StatelessWidget {
  final Map c;
  final double Function(dynamic) toDouble;
  const _CollectionCard({required this.c, required this.toDouble});

  @override
  Widget build(BuildContext context) {
    final isPaid = c['payment_status'] == 'paid';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  c['household']?['name']?.toString() ?? '-',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPaid ? 'COMPLETED' : 'PENDING',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 4, children: [
            _Tag(c['date']?.toString() ?? '-', Icons.calendar_today, Colors.blue),
            _Tag(
              (c['waste_type'] ?? '').toString().toUpperCase(),
              Icons.recycling,
              AppTheme.primary,
            ),
            _Tag('Rs ${toDouble(c['amount']).toStringAsFixed(0)}', Icons.currency_rupee, Colors.orange),
            _Tag((c['payment_method'] ?? '').toString().toUpperCase(), Icons.payments, Colors.purple),
          ]),
          const SizedBox(height: 4),
          Text(
            'Worker: ${c['worker']?['worker_id'] ?? '-'}  •  Ward: ${c['household']?['ward']?['name'] ?? '-'}',
            style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight),
          ),
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Card(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark), overflow: TextOverflow.ellipsis),
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textLight)),
      ])),
    ]),
  );
}

class _Tag extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _Tag(this.text, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 4),
      Text(text, style: GoogleFonts.poppins(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    ]),
  );
}
