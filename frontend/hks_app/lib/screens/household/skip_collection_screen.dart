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
  bool _submitting = false;
  List<dynamic> _existingRequests = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final reqs = await _api.getSkipRequests();
      setState(() { _existingRequests = reqs; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await _api.createSkipRequest({
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'reason': _reasonCtrl.text.trim(),
        'payment_action': 'defer',   // default — kept for model compatibility
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Skip request sent for ${DateFormat('dd MMM yyyy').format(_selectedDate)}. Your ward worker has been notified.',
          ),
          backgroundColor: Colors.orange,
        ));
        _reasonCtrl.clear();
        _load();
      }
    } catch (e) {
      if (mounted) {
        // Try to extract a clean message from DRF error response
        String msg = 'Could not send skip request. Please try again.';
        final raw = e.toString();
        if (raw.contains('No household profile')) {
          msg = 'Your account is not linked to a household. Please contact admin.';
        } else if (raw.contains('400') || raw.contains('non_field_errors') || raw.contains('detail')) {
          // Try to get the actual server error message
          try {
            final dioErr = e as dynamic;
            final data = dioErr.response?.data;
            if (data is Map) {
              final detail = data['detail'] ?? data['non_field_errors']?.first ?? data.values.first;
              if (detail != null) msg = detail.toString();
            } else if (data is String) {
              msg = data;
            }
          } catch (_) {}
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
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
                        'Notify your ward worker if you don\'t need collection on a specific day. '
                        'This is just a notification — no payment changes.',
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
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final today = DateTime.now();
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: today,
                      lastDate: today.add(const Duration(days: 60)),
                      helpText: 'Select Skip Date',
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
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(_selectedDate),
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: AppTheme.textLight),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),

                // Reason
                Text('Reason (optional)', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _reasonCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g. I will not be home today',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.edit_note),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send),
                    label: Text(
                      _submitting ? 'Sending Request...' : 'Send Skip Request',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
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
                      leading: CircleAvatar(
                        backgroundColor: r['status'] == 'acknowledged'
                            ? Colors.green.shade50
                            : Colors.orange.shade50,
                        child: Icon(
                          r['status'] == 'acknowledged' ? Icons.check_circle : Icons.hourglass_empty,
                          color: r['status'] == 'acknowledged' ? Colors.green : Colors.orange,
                        ),
                      ),
                      title: Text(
                        r['date'].toString(),
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: r['reason'] != null && r['reason'].toString().isNotEmpty
                          ? Text(r['reason'].toString(), style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight))
                          : null,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: r['status'] == 'acknowledged' ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          r['status'] == 'acknowledged' ? 'Noted' : 'Pending',
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
