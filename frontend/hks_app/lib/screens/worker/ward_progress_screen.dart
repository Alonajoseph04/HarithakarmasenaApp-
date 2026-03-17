import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class WardProgressScreen extends StatefulWidget {
  const WardProgressScreen({super.key});
  @override State<WardProgressScreen> createState() => _WardProgressScreenState();
}

class _WardProgressScreenState extends State<WardProgressScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _workerData;
  Map<String, dynamic>? _progress;
  List<dynamic> _allWards = [];
  int? _selectedWardId;
  bool _loading = true;
  bool _notifying = false;
  bool _qrLookingUp = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);

    // ── Step 1: Load wards independently — always loads, never skipped ──
    List<dynamic> wards = [];
    try {
      wards = await _api.getWards();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not load wards: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ));
      }
    }

    // ── Step 2: Load worker profile — failure is non-fatal ──
    Map<String, dynamic>? worker;
    try {
      worker = await _api.getWorkerMe();
    } catch (_) {
      // Worker profile not linked to this user; continue without it
    }

    // Prefer worker's assigned ward; fall back to first available
    int? wardId = _selectedWardId;
    if (wardId == null && worker != null) {
      wardId = worker['ward']?['id'] as int?;
    }
    if (wardId != null && !wards.any((w) => w['id'] == wardId)) {
      wardId = null;
    }
    if (wardId == null && wards.isNotEmpty) {
      wardId = wards.first['id'] as int?;
    }

    // ── Step 3: Load ward progress ──
    Map<String, dynamic>? prog;
    if (wardId != null) {
      try {
        prog = await _api.getWardProgress(wardId);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _workerData = worker;
        _allWards = wards;
        _selectedWardId = wardId;
        _progress = prog;
        _loading = false;
      });
    }
  }

  Future<void> _selectWard(int wardId) async {
    setState(() { _selectedWardId = wardId; _loading = true; });
    try {
      final prog = await _api.getWardProgress(wardId);
      setState(() { _progress = prog; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _notifyWard() async {
    final wardName = _allWards.firstWhere(
      (w) => w['id'] == _selectedWardId, orElse: () => {'name': 'your ward'})['name'];

    // Step 1: Pick a collection date — only today or future dates
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: todayOnly,
      firstDate: todayOnly,
      lastDate: DateTime(2100),
      helpText: 'Select Collection Date',
      confirmText: 'Next',
      cancelText: 'Cancel',
    );
    if (pickedDate == null) return; // user cancelled

    final dateStr =
        '${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}';

    // Step 2: Confirm before sending
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [
          const Icon(Icons.campaign, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('Notify Households'),
        ]),
        content: Text(
          'Send a collection notification to all households in $wardName for $dateStr?',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Send Notification'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _notifying = true);
    try {
      final scheduledDateIso =
          '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
      final res = await _api.notifyWard(
        wardId: _selectedWardId,
        message: 'Waste collection is scheduled for $dateStr in $wardName. Please keep your waste ready.',
        scheduledDate: scheduledDateIso,
      );
      if (mounted) {
        final total = res['notified'] ?? 0;
        final appNotified = res['notified_app'] ?? 0;
        final String msg;
        if (appNotified > 0 && appNotified == total) {
          msg = 'All $total households in $wardName notified for $dateStr ✓';
        } else if (appNotified > 0) {
          msg = 'All $total households in $wardName scheduled for $dateStr. '
              '$appNotified received in-app alerts (${total - appNotified} have no app account yet).';
        } else {
          msg = 'Collection scheduled for $wardName on $dateStr. '
              '$total households in ward — none have app accounts yet, '
              'so no in-app alerts were sent.';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _notifying = false);
    }
  }

  /// Direct manual QR entry — no scanner screen needed (works on web too)
  Future<void> _showManualQrDialog() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.qr_code, color: AppTheme.primary),
          SizedBox(width: 8),
          Text('Enter QR Code'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'HKS-A1B2C3D4E5',
                prefixIcon: Icon(Icons.qr_code_scanner),
                labelText: 'Household QR Code',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the QR code printed on the household card.',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, ctrl.text.trim()),
            child: const Text('Look Up'),
          ),
        ],
      ),
    );
    if (code == null || code.isEmpty) return;

    setState(() => _qrLookingUp = true);
    try {
      Map<String, dynamic> household;
      try {
        household = await _api.getHouseholdByQr(code);
      } catch (_) {
        household = await _api.getHouseholdByCode(code);
      }
      if (mounted) {
        setState(() => _qrLookingUp = false);
        context.push('/worker/collect', extra: household);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _qrLookingUp = false);
        final msg = e.toString().contains('404') || e.toString().contains('not found')
            ? 'No household found for "$code". Check the code and try again.'
            : 'Error: $e';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.wardCollection),
        actions: [
          const LangToggleButton(),
          const ThemeToggleButton(),
          IconButton(icon: const Icon(Icons.logout),
              onPressed: () async { await auth.logout(); if (mounted) context.go('/'); }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Worker info card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(children: [
                      const CircleAvatar(radius: 28, backgroundColor: Colors.white30,
                          child: Icon(Icons.person, color: Colors.white, size: 32)),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${auth.user?['first_name'] ?? ''} ${auth.user?['last_name'] ?? ''}',
                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        Text('ID: ${_workerData?['worker_id'] ?? '-'}',
                            style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
                      ])),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // Ward selector
                  Text(s.selectWard, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (_allWards.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(child: Text('No wards found. Please ask an admin to create wards.',
                            style: GoogleFonts.poppins(fontSize: 13))),
                      ]),
                    )
                  else
                  DropdownButtonFormField<int>(
                    value: _selectedWardId,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.location_city),
                      hintText: s.chooseWard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _allWards.map<DropdownMenuItem<int>>((w) =>
                      DropdownMenuItem<int>(value: w['id'] as int, child: Text(w['name'].toString()))).toList(),
                    onChanged: (id) { if (id != null) _selectWard(id); },
                  ),
                  const SizedBox(height: 20),

                  if (_selectedWardId != null && _progress != null) ...[
                    // Progress stats
                    Text(s.todayProgress, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _ProgressCard(s.totalHouses, '${_progress!['total_houses']}', Colors.blue)),
                      const SizedBox(width: 10),
                      Expanded(child: _ProgressCard(s.visited, '${_progress!['visited']}', AppTheme.primary)),
                      const SizedBox(width: 10),
                      Expanded(child: _ProgressCard(s.remaining, '${_progress!['remaining']}', Colors.orange)),
                    ]),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                      ),
                      child: Row(children: [
                        const Icon(Icons.currency_rupee, color: AppTheme.primary, size: 28),
                        const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(s.expectedCollection, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
                          Text('Rs ${(double.tryParse(_progress!['expected_amount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ]),
                      ]),
                    ),
                    const SizedBox(height: 20),

                    // Pie chart
                    if ((_progress!['total_houses'] as int) > 0) ...[
                      Text(s.collectionProgress, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Container(
                        height: 200,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white, borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                        ),
                        child: Row(children: [
                          Expanded(
                            child: PieChart(PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: (_progress!['visited'] as int).toDouble(),
                                  color: AppTheme.primary,
                                  title: '${_progress!['visited']}',
                                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  radius: 70,
                                ),
                                PieChartSectionData(
                                  value: (_progress!['remaining'] as int).toDouble(),
                                  color: Colors.orange.shade200,
                                  title: '${_progress!['remaining']}',
                                  titleStyle: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                                  radius: 70,
                                ),
                              ],
                              centerSpaceRadius: 30,
                            )),
                          ),
                          Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            _Legend(AppTheme.primary, s.visited),
                            const SizedBox(height: 8),
                            _Legend(Colors.orange.shade200, s.remaining),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],

                  // Notify ward button
                  if (_selectedWardId != null) ...[
                    OutlinedButton.icon(
                      icon: _notifying
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.campaign, color: Colors.orange),
                      label: Text(
                        _notifying ? s.loading : s.scheduleNotification,
                        style: GoogleFonts.poppins(color: Colors.orange, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _notifying ? null : _notifyWard,
                    ),
                    const SizedBox(height: 4),
                    Text('Tap to notify all households in the ward immediately',
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                  ],

                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: Text(s.scanHouseholdQr),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: _selectedWardId == null
                        ? null
                        : () => context.push('/worker/scan', extra: {'ward_id': _selectedWardId}),
                  ),
                  const SizedBox(height: 10),
                  // Direct manual QR entry — always works (no camera needed)
                  OutlinedButton.icon(
                    icon: _qrLookingUp
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.keyboard, color: AppTheme.primary),
                    label: Text(
                      _qrLookingUp ? 'Looking up...' : 'Enter QR Code Manually',
                      style: GoogleFonts.poppins(color: AppTheme.primary, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: (_selectedWardId == null || _qrLookingUp) ? null : _showManualQrDialog,
                  ),
                  if (_selectedWardId == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(s.selectWardFirst,
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.red),
                          textAlign: TextAlign.center),
                    ),
                ],
              ),
            ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ProgressCard(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Column(children: [
      Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight), textAlign: TextAlign.center),
    ]),
  );
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 6),
    Text(label, style: GoogleFonts.poppins(fontSize: 12)),
  ]);
}
