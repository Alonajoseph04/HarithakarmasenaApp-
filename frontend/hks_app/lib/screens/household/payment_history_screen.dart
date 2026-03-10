import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});
  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final _api = ApiService();
  List<dynamic> _collections = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final h = await _api.getHouseholdMe();
      final cols = await _api.getCollections(householdId: h['id'] as int);
      setState(() { _collections = cols; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  double get _totalPaid => _collections
      .where((c) => c['payment_status'] == 'paid')
      .fold(0.0, (s, c) => s + (double.tryParse(c['amount']?.toString() ?? '0') ?? 0.0));

  double get _totalPending => _collections
      .where((c) => c['payment_status'] == 'pending')
      .fold(0.0, (s, c) => s + (double.tryParse(c['amount']?.toString() ?? '0') ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _PayStat('Total Paid', 'Rs ${_totalPaid.toStringAsFixed(0)}', Colors.white, Colors.white60),
                      Container(width: 1, height: 40, color: Colors.white38),
                      _PayStat('Pending', 'Rs ${_totalPending.toStringAsFixed(0)}',
                          _totalPending > 0 ? Colors.red.shade100 : Colors.white,
                          _totalPending > 0 ? Colors.red.shade200 : Colors.white60),
                      Container(width: 1, height: 40, color: Colors.white38),
                      _PayStat('Records', '${_collections.length}', Colors.white, Colors.white60),
                    ],
                  ),
                ),
                // Pending alert
                if (_totalPending > 0)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text('You have Rs ${_totalPending.toStringAsFixed(0)} pending',
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _collections.length,
                    itemBuilder: (ctx, i) {
                      final c = _collections[i];
                      final isPaid = c['payment_status'] == 'paid';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border(
                              left: BorderSide(
                                color: isPaid ? AppTheme.primary : Colors.red,
                                width: 4,
                              ),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(isPaid ? Icons.check_circle : Icons.pending,
                                  color: isPaid ? AppTheme.primary : Colors.red, size: 28),
                            ]),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Rs ${c['amount']}',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold, fontSize: 18,
                                        color: isPaid ? AppTheme.primary : Colors.red)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(isPaid ? 'PAID' : 'PENDING',
                                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold,
                                          color: isPaid ? Colors.green.shade700 : Colors.red.shade700)),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              '${c['date']} • ${(c['payment_method'] as String).toUpperCase()} • ${(c['waste_type'] as String).toUpperCase()} ${c['weight']}kg',
                              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _PayStat extends StatelessWidget {
  final String label, value;
  final Color valueColor, labelColor;
  const _PayStat(this.label, this.value, this.valueColor, this.labelColor);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: valueColor)),
    Text(label, style: GoogleFonts.poppins(fontSize: 10, color: labelColor)),
  ]);
}
