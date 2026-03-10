import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});
  @override State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _api = ApiService();
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _target = 'all';
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast Notification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.broadcast_on_personal, color: AppTheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Admin Broadcast', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.primary)),
                  Text('Send announcements to Workers or Households', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
                ])),
              ]),
            ),
            const SizedBox(height: 24),
            Text('Target Audience', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 10),
            Row(children: [
              for (final t in [('all', 'Everyone'), ('workers', 'Workers'), ('households', 'Households')])
                Expanded(child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _target = t.$1),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _target == t.$1 ? AppTheme.primary : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _target == t.$1 ? AppTheme.primary : Colors.grey.shade300),
                      ),
                      child: Text(t.$2, textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500,
                              color: _target == t.$1 ? Colors.white : AppTheme.textDark)),
                    ),
                  ),
                )),
            ]),
            const SizedBox(height: 20),
            Text('Message Title', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(
              hintText: 'e.g., Collection Schedule Update',
            )),
            const SizedBox(height: 16),
            Text('Message Body', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(controller: _msgCtrl, maxLines: 5, decoration: const InputDecoration(
              hintText: 'Type your announcement here...',
            )),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: Text(_sending ? 'Sending...' : 'Send Broadcast'),
              onPressed: _sending ? null : () async {
                if (_titleCtrl.text.trim().isEmpty || _msgCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in title and message')));
                  return;
                }
                setState(() => _sending = true);
                try {
                  await _api.broadcast(_titleCtrl.text, _msgCtrl.text, _target);
                  _titleCtrl.clear(); _msgCtrl.clear();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Broadcast sent successfully!'),
                          backgroundColor: AppTheme.primary));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                } finally {
                  if (mounted) setState(() => _sending = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
