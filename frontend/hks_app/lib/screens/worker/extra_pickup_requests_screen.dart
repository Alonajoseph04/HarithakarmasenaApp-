import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Worker screen: tabbed view showing Extra Pickup Requests and Household Skip Requests.
class ExtraPickupRequestsScreen extends StatefulWidget {
  const ExtraPickupRequestsScreen({super.key});
  @override
  State<ExtraPickupRequestsScreen> createState() => _ExtraPickupRequestsScreenState();
}

class _ExtraPickupRequestsScreenState extends State<ExtraPickupRequestsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late TabController _tabController;

  // Extra pickup
  List<dynamic> _pickupRequests = [];
  bool _pickupLoading = true;

  // Skip requests
  List<dynamic> _skipRequests = [];
  bool _skipLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0) {
          _loadPickup();
        } else {
          _loadSkip();
        }
      }
    });
    _loadPickup();
    _loadSkip();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPickup() async {
    setState(() => _pickupLoading = true);
    try {
      final reqs = await _api.getExtraPickupRequests();
      if (mounted) setState(() { _pickupRequests = reqs; _pickupLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _pickupLoading = false);
    }
  }

  Future<void> _loadSkip() async {
    setState(() => _skipLoading = true);
    try {
      final reqs = await _api.getWorkerSkipRequests();
      if (mounted) setState(() { _skipRequests = reqs; _skipLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _skipLoading = false);
    }
  }

  Future<void> _approve(int id) async {
    try {
      await _api.approveExtraPickup(id);
      if (mounted) {
        await _loadPickup();
        _flash(Colors.green, context.read<LanguageProvider>().strings.approvedLabel);
      }
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
      if (mounted) { await _loadPickup(); _flash(Colors.red.shade300, s.rejectedLabel); }
    } catch (e) { _flash(AppTheme.error, 'Error: $e'); }
  }

  Future<void> _acknowledgeSkip(int id) async {
    try {
      await _api.acknowledgeSkipRequest(id);
      if (mounted) {
        await _loadSkip();
        _flash(Colors.green, 'Skip request acknowledged');
      }
    } catch (e) {
      _flash(AppTheme.error, 'Error: $e');
    }
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
    final pendingPickup = _pickupRequests.where((r) => r['status'] == 'pending').length;
    final pendingSkip = _skipRequests.where((r) => r['status'] == 'pending').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.extraPickupRequests),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              _loadPickup();
              _loadSkip();
            },
          ),
          const LangToggleButton(),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_box_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Extra Pickup', style: GoogleFonts.poppins(fontSize: 13)),
                  if (pendingPickup > 0) ...[
                    const SizedBox(width: 6),
                    _Badge(count: pendingPickup, color: Colors.orange),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.skip_next_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Skip Requests', style: GoogleFonts.poppins(fontSize: 13)),
                  if (pendingSkip > 0) ...[
                    const SizedBox(width: 6),
                    _Badge(count: pendingSkip, color: Colors.red),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Extra Pickup Requests ──────────────────────────
          _pickupLoading
              ? const Center(child: CircularProgressIndicator())
              : _pickupRequests.isEmpty
                  ? const _EmptyState(icon: Icons.inbox_rounded, label: 'No extra pickup requests\nin the last 7 days')
                  : RefreshIndicator(
                      onRefresh: _loadPickup,
                      child: ListView(
                        padding: const EdgeInsets.all(14),
                        children: [
                          ..._pickupRequests
                              .where((r) => r['status'] == 'pending')
                              .map((r) => _RequestCard(
                                    req: r, s: s,
                                    onApprove: () => _approve(r['id'] as int),
                                    onReject: () => _reject(r['id'] as int),
                                  )),
                          if (_pickupRequests.any((r) => r['status'] != 'pending')) ...[
                            const _SectionHeader(label: "Today's Reviewed", color: Colors.blue),
                            ..._pickupRequests
                                .where((r) => r['status'] != 'pending')
                                .map((r) => _RequestCard(req: r, s: s)),
                          ],
                        ],
                      ),
                    ),

          // ── Tab 2: Skip Requests ──────────────────────────────────
          _skipLoading
              ? const Center(child: CircularProgressIndicator())
              : _skipRequests.isEmpty
                  ? const _EmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'No skip requests from\nhouseholds in your ward',
                    )
                  : RefreshIndicator(
                      onRefresh: _loadSkip,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: _skipRequests.length,
                        itemBuilder: (ctx, i) {
                          final r = _skipRequests[i];
                          return _SkipRequestCard(
                            req: r,
                            onAcknowledge: () => _acknowledgeSkip(r['id'] as int),
                          );
                        },
                      ),
                    ),
        ],
      ),
    );
  }
}

// ─── Widgets ───────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final int count;
  final Color color;
  const _Badge({required this.count, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 20, height: 20,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Center(
      child: Text('$count',
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyState({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 64, color: Colors.grey),
      const SizedBox(height: 12),
      Text(label, style: GoogleFonts.poppins(color: AppTheme.textLight, fontSize: 15)),
    ]),
  );
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(label,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
  );
}

/// Card for Extra Pickup Requests (approve / reject)
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
    final statusColor = status == 'approved'
        ? Colors.green
        : status == 'rejected'
            ? Colors.red
            : Colors.orange;
    final statusLabel = status == 'approved'
        ? s.approvedLabel
        : status == 'rejected'
            ? s.rejectedLabel
            : s.pending;

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
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: statusColor, fontWeight: FontWeight.w600)),
            ),
          ]),
          if ((req['notes'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"${req['notes']}"',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppTheme.textLight, fontStyle: FontStyle.italic)),
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

/// Card for Skip Requests (acknowledge)
class _SkipRequestCard extends StatelessWidget {
  final Map<String, dynamic> req;
  final VoidCallback onAcknowledge;
  const _SkipRequestCard({required this.req, required this.onAcknowledge});

  @override
  Widget build(BuildContext context) {
    final householdName = req['household_name'] ?? req['household']?['name'] ?? 'Unknown';
    final date = req['date'] ?? '';
    final reason = (req['reason'] ?? '').toString().trim();
    final status = req['status'] ?? 'pending';
    final isPending = status == 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.skip_next_rounded, color: Colors.orange, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(householdName,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
              Row(children: [
                const Icon(Icons.calendar_today, size: 13, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(
                  'Skip on $date',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight),
                ),
              ]),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isPending ? Colors.orange.withAlpha(25) : Colors.green.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isPending ? Colors.orange : Colors.green),
              ),
              child: Text(
                isPending ? 'Pending' : 'Noted',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isPending ? Colors.orange : Colors.green,
                ),
              ),
            ),
          ]),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                const Icon(Icons.comment_outlined, size: 14, color: AppTheme.textLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(reason,
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: AppTheme.textLight, fontStyle: FontStyle.italic)),
                ),
              ]),
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onAcknowledge,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text('Acknowledge',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(0, 42),
                ),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}
