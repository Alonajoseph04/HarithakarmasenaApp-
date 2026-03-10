import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Worker screen: view and approve/reject today's extra pickup requests.
class ExtraPickupRequestsScreen extends StatefulWidget {
  const ExtraPickupRequestsScreen({super.key});
  @override
  State<ExtraPickupRequestsScreen> createState() => _ExtraPickupRequestsScreenState();
}

class _ExtraPickupRequestsScreenState extends State<ExtraPickupRequestsScreen> {
  final _api = ApiService();
  List<dynamic> _requests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final reqs = await _api.getExtraPickupRequests();
      if (mounted) setState(() { _requests = reqs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(int id) async {
    try {
      await _api.approveExtraPickup(id);
      if (mounted) { await _load(); _flash(Colors.green, context.read<LanguageProvider>().strings.approvedLabel); }
    } catch (e) { _flash(AppTheme.error, 'Error: $e'); }
  }

  Future<void> _reject(int id) async {
    final s = context.read<LanguageProvider>().strings;
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.rejectReq),
        content: TextField(
          controller: reasonCtrl,
          decoration: InputDecoration(labelText: s.rejectionReason),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.rejectReq)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _api.rejectExtraPickup(id, reason: reasonCtrl.text.trim());
      if (mounted) { await _load(); _flash(Colors.red.shade300, s.rejectedLabel); }
    } catch (e) { _flash(AppTheme.error, 'Error: $e'); }
  }

  void _flash(Color bg, String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg, duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    final pending = _requests.where((r) => r['status'] == 'pending').toList();
    final reviewed = _requests.where((r) => r['status'] != 'pending').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.extraPickupRequests),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
          const LangToggleButton(),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(s.noExtraRequests,
                      style: GoogleFonts.poppins(color: AppTheme.textLight, fontSize: 15)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(14),
                    children: [
                      if (pending.isNotEmpty) ...[
                        _SectionHeader(label: '${s.pendingRequests} (${pending.length})', color: Colors.orange),
                        ...pending.map((r) => _RequestCard(
                          req: r, s: s,
                          onApprove: () => _approve(r['id'] as int),
                          onReject: () => _reject(r['id'] as int),
                        )),
                        const SizedBox(height: 16),
                      ],
                      if (reviewed.isNotEmpty) ...[
                        _SectionHeader(label: 'Today\'s Reviewed', color: Colors.blue),
                        ...reviewed.map((r) => _RequestCard(req: r, s: s)),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
  );
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> req;
  final AppStrings s;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _RequestCard({required this.req, required this.s, this.onApprove, this.onReject});

  @override
  Widget build(BuildContext context) {
    final status = req['status'] as String? ?? 'pending';
    final isPending = status == 'pending';
    final statusColor = status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange;
    final statusLabel = status == 'approved' ? s.approvedLabel : status == 'rejected' ? s.rejectedLabel : s.pending;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppTheme.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(req['waste_type_display'] ?? req['waste_type'] ?? '',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(req['household_name'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
              if ((req['household_address'] ?? '').toString().isNotEmpty)
                Text(req['household_address'].toString(),
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor),
              ),
              child: Text(statusLabel,
                  style: GoogleFonts.poppins(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
            ),
          ]),
          if ((req['notes'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"${req['notes']}"',
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight, fontStyle: FontStyle.italic)),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(s.approve),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                  label: Text(s.rejectReq, style: const TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
