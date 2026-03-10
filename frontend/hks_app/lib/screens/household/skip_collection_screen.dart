import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class SkipCollectionScreen extends StatefulWidget {
  const SkipCollectionScreen({super.key});
  @override
  State<SkipCollectionScreen> createState() => _SkipCollectionScreenState();
}

class _SkipCollectionScreenState extends State<SkipCollectionScreen> {
  final _api = ApiService();
  final _reasonCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _paymentAction = 'defer';
  bool _submitting = false;
  List<dynamic> _existingRequests = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final reqs = await _api.getSkipRequests();
      setState(() { _existingRequests = reqs; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await _api.createSkipRequest({
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'reason': _reasonCtrl.text.trim(),
        'payment_action': _paymentAction,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Skip request sent for ${DateFormat('dd MMM yyyy').format(_selectedDate)}. Workers have been notified.'),
            backgroundColor: AppTheme.primary,
          ),
        );
        _reasonCtrl.clear();
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Skip Collection')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(children: [
                    const Icon(Icons.info_outline, color: Colors.orange, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Use this if waste collection is not required on a particular day. Your ward worker will be notified.',
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                // Date picker
                Text('Select Date', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (d != null) setState(() => _selectedDate = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      const Icon(Icons.calendar_today, color: AppTheme.primary),
                      const SizedBox(width: 10),
                      Text(DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),

                // Payment action
                Text('Payment for this day', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: _PayOption(
                    label: 'Defer to Next Month',
                    icon: Icons.schedule,
                    selected: _paymentAction == 'defer',
                    onTap: () => setState(() => _paymentAction = 'defer'),
                    color: Colors.orange,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _PayOption(
                    label: 'Waive (No Charge)',
                    icon: Icons.money_off,
                    selected: _paymentAction == 'waive',
                    onTap: () => setState(() => _paymentAction = 'waive'),
                    color: Colors.green,
                  )),
                ]),
                const SizedBox(height: 16),

                // Reason
                Text('Reason (optional)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g. I will not be home today',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: Text(_submitting ? 'Sending...' : 'Send Skip Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ),

                // Existing skip requests
                if (_existingRequests.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  Text('Previous Requests', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  ..._existingRequests.map((r) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(
                        r['status'] == 'acknowledged' ? Icons.check_circle : Icons.hourglass_empty,
                        color: r['status'] == 'acknowledged' ? Colors.green : Colors.orange,
                      ),
                      title: Text(r['date'].toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text('${r['payment_action'] == 'defer' ? 'Defer to next month' : 'Waive'}  •  ${r['reason'] ?? ''}',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: r['status'] == 'acknowledged' ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r['status'] == 'acknowledged' ? 'Acknowledged' : 'Pending',
                          style: GoogleFonts.poppins(
                            fontSize: 10, fontWeight: FontWeight.bold,
                            color: r['status'] == 'acknowledged' ? Colors.green.shade700 : Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ),
                  )),
                ],
              ],
            ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _PayOption({required this.label, required this.icon, required this.selected, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected ? color.withOpacity(0.12) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 2 : 1),
      ),
      child: Column(children: [
        Icon(icon, color: selected ? color : Colors.grey, size: 26),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, color: selected ? color : AppTheme.textLight,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal), textAlign: TextAlign.center),
      ]),
    ),
  );
}
