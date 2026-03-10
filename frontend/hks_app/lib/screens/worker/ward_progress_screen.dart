import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final futures = await Future.wait([_api.getWorkerMe(), _api.getWards()]);
      final worker = futures[0] as Map<String, dynamic>;
      final wards = futures[1] as List<dynamic>;

      // Only use a wardId that actually exists in the fetched list — prevents dropdown assertion crash
      int? wardId = _selectedWardId ?? (worker['ward']?['id'] as int?);
      if (wardId != null && !wards.any((w) => w['id'] == wardId)) {
        wardId = null; // reset if not in list
      }

      Map<String, dynamic>? prog;
      if (wardId != null) {
        prog = await _api.getWardProgress(wardId);
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
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load wards: $e'), backgroundColor: Colors.red),
        );
      }
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
    // Must pick a date at least 3 days from now
    final minDate = DateTime.now().add(const Duration(days: 3));
    final picked = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'Select Collection Date (min 3 days ahead)',
    );
    if (picked == null) return;

    setState(() => _notifying = true);
    final wardName = _allWards.firstWhere(
      (w) => w['id'] == _selectedWardId, orElse: () => {'name': 'your ward'})['name'];
    try {
      final res = await _api.notifyWard(
        message: 'Waste collection is scheduled for ${DateFormat('EEE, dd MMM yyyy').format(picked)} in $wardName. Please keep your waste ready.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Notified ${res['notified']} households for ${DateFormat('dd MMM').format(picked)}'),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _notifying = false);
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
                    Text(s.minThreeDays,
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
