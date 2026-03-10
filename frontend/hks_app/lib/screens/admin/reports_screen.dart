import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _api = ApiService();
  List<dynamic> _collections = [];
  List<dynamic> _workers = [];
  List<dynamic> _wards = [];
  bool _loading = true;
  String? _error;
  // Filters
  int? _selectedWardId;
  int? _selectedWorkerId;

  @override
  void initState() {
    super.initState();
    _load();
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
        _workers = results[1];
        _wards = results[2];
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // Safe number parsing from either num or String (DRF decimals come as strings)
  double _toDouble(dynamic val) => double.tryParse(val?.toString() ?? '0') ?? 0.0;

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
      return true;
    }).toList();
  }

  double get _totalWeight => _filtered.fold(0.0, (s, c) => s + _toDouble(c['weight']));
  double get _totalAmount => _filtered.fold(0.0, (s, c) => s + _toDouble(c['amount']));
  double get _paidAmount => _filtered
      .where((c) => c['payment_status'] == 'paid')
      .fold(0.0, (s, c) => s + _toDouble(c['amount']));

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Reports'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 56, color: AppTheme.error),
                        const SizedBox(height: 12),
                        Text('Failed to load reports', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(_error!, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight), textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          onPressed: _load,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Filters row
                      Row(children: [
                        Expanded(child: DropdownButtonFormField<int?>(
                          value: _selectedWardId,
                          decoration: const InputDecoration(
                            labelText: 'Filter by Ward',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Wards')),
                            ..._wards.map((w) => DropdownMenuItem<int?>(
                              value: w['id'] as int,
                              child: Text(w['name'].toString(), overflow: TextOverflow.ellipsis),
                            )),
                          ],
                          onChanged: (v) => setState(() { _selectedWardId = v; }),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: DropdownButtonFormField<int?>(
                          value: _selectedWorkerId,
                          decoration: const InputDecoration(
                            labelText: 'Filter by Worker',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All Workers')),
                            ..._workers.map((w) => DropdownMenuItem<int?>(
                              value: w['id'] as int,
                              child: Text(w['worker_id'].toString()),
                            )),
                          ],
                          onChanged: (v) => setState(() { _selectedWorkerId = v; }),
                        )),
                      ]),
                      const SizedBox(height: 16),

                      // Summary cards
                      Row(children: [
                        Expanded(child: _Card('Collections', '${filtered.length}', Icons.list_alt, Colors.blue)),
                        const SizedBox(width: 10),
                        Expanded(child: _Card('Total Waste', '${_totalWeight.toStringAsFixed(1)}kg', Icons.recycling, AppTheme.primary)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: _Card('Total Billed', 'Rs ${_totalAmount.toStringAsFixed(0)}', Icons.receipt, Colors.orange)),
                        const SizedBox(width: 10),
                        Expanded(child: _Card('Paid', 'Rs ${_paidAmount.toStringAsFixed(0)}', Icons.check_circle, Colors.green)),
                      ]),
                      const SizedBox(height: 10),
                      _Card(
                        'Households Covered',
                        '${filtered.map((c) => c['household']?['id']).whereType<int>().toSet().length}',
                        Icons.home,
                        Colors.purple,
                      ),

                      const SizedBox(height: 20),

                      // Collection list
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Collection Records', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text('${filtered.length} records', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
                        ],
                      ),
                      const SizedBox(height: 10),

                      if (filtered.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(children: [
                              const Icon(Icons.inbox, size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text('No collections found for the selected filters.',
                                  style: GoogleFonts.poppins(color: AppTheme.textLight), textAlign: TextAlign.center),
                            ]),
                          ),
                        )
                      else
                        ...filtered.map((c) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                        color: c['payment_status'] == 'paid'
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        (c['payment_status'] ?? '').toString().toUpperCase(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: c['payment_status'] == 'paid'
                                              ? Colors.green.shade800
                                              : Colors.red.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _Tag(c['date']?.toString() ?? '-', Icons.calendar_today, Colors.blue),
                                    _Tag(
                                      '${(c['waste_type'] ?? '').toString().toUpperCase()} ${_toDouble(c['weight']).toStringAsFixed(1)}kg',
                                      Icons.recycling,
                                      AppTheme.primary,
                                    ),
                                    _Tag('Rs ${_toDouble(c['amount']).toStringAsFixed(0)}', Icons.currency_rupee, Colors.orange),
                                    _Tag((c['payment_method'] ?? '').toString().toUpperCase(), Icons.payments, Colors.purple),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Worker: ${c['worker']?['worker_id'] ?? '-'}  •  Ward: ${c['household']?['ward']?['name'] ?? '-'}',
                                  style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight),
                                ),
                              ],
                            ),
                          ),
                        )),
                    ],
                  ),
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
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Row(children: [
      Icon(icon, color: color, size: 26),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          overflow: TextOverflow.ellipsis,
        ),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight)),
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
