import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

const _wasteTypes = [
  ('plastic',  'Plastic',  Icons.recycling,          Colors.blue),
  ('organic',  'Organic',  Icons.compost,             Colors.green),
  ('paper',    'Paper',    Icons.article,             Colors.brown),
  ('glass',    'Glass',    Icons.wine_bar,            Colors.cyan),
  ('metal',    'Metal',    Icons.hardware,            Colors.grey),
  ('ewaste',   'E-Waste',  Icons.electrical_services, Colors.purple),
  ('mixed',    'Mixed',    Icons.delete_outline,      Colors.orange),
];

/// Household screen: request extra waste type to be picked up today.
class ExtraPickupScreen extends StatefulWidget {
  const ExtraPickupScreen({super.key});
  @override
  State<ExtraPickupScreen> createState() => _ExtraPickupScreenState();
}

class _ExtraPickupScreenState extends State<ExtraPickupScreen> {
  final _api = ApiService();
  final _notesCtrl = TextEditingController();
  String? _selectedType;
  bool _submitting = false;
  bool _submitted = false;
  List<dynamic> _myRequests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() => _loading = true);
    try {
      final reqs = await _api.getExtraPickupRequests();
      if (mounted) setState(() { _myRequests = reqs; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_selectedType == null) return;
    setState(() => _submitting = true);
    try {
      await _api.createExtraPickupRequest(
        wasteType: _selectedType!,
        notes: _notesCtrl.text.trim(),
      );
      if (mounted) {
        setState(() { _submitted = true; _submitting = false; });
        await _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.requestExtraPickup),
        actions: const [LangToggleButton(), ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.primary.withAlpha(30), AppTheme.secondary.withAlpha(20)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withAlpha(50)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(s.extraPickupSubtitle,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textDark))),
            ]),
          ),
          const SizedBox(height: 24),

          if (_submitted) ...[
            // Success state
            Center(child: Column(children: [
              const Icon(Icons.check_circle_rounded, color: Colors.green, size: 60),
              const SizedBox(height: 12),
              Text(s.requestSent,
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 6),
              Text(s.requestSentDesc,
                  style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textLight),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: Text(s.requestExtraPickup),
                onPressed: () => setState(() { _submitted = false; _selectedType = null; _notesCtrl.clear(); }),
              ),
            ])),
          ] else ...[
            // Waste type picker
            Text(s.selectWasteType,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: _wasteTypes.map((t) {
                final (key, label, icon, color) = t;
                final selected = _selectedType == key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: selected ? color : color.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color, width: selected ? 2.5 : 1),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(icon, color: selected ? Colors.white : color, size: 28),
                      const SizedBox(height: 4),
                      Text(label,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : color),
                          textAlign: TextAlign.center),
                    ]),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Notes
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: s.additionalNotes,
                prefixIcon: const Icon(Icons.note_rounded),
              ),
            ),
            const SizedBox(height: 22),

            ElevatedButton.icon(
              onPressed: (_submitting || _selectedType == null) ? null : _submit,
              icon: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(_submitting ? s.loading : s.requestExtraPickup),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: _selectedType != null ? AppTheme.primary : Colors.grey,
              ),
            ),
          ],

          // My past requests today
          if (_myRequests.isNotEmpty) ...[
            const SizedBox(height: 28),
            Text(s.pendingRequests,
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ..._myRequests.map((r) => _RequestStatusCard(req: r, s: s)),
          ],
        ],
      ),
    );
  }
}

class _RequestStatusCard extends StatelessWidget {
  final Map<String, dynamic> req;
  final AppStrings s;
  const _RequestStatusCard({required this.req, required this.s});

  @override
  Widget build(BuildContext context) {
    final status = req['status'] as String? ?? 'pending';
    final color = status == 'approved' ? Colors.green : status == 'rejected' ? Colors.red : Colors.orange;
    final label = status == 'approved' ? s.approvedLabel : status == 'rejected' ? s.rejectedLabel : s.pending;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(
            status == 'approved' ? Icons.check_circle : status == 'rejected' ? Icons.cancel : Icons.pending,
            color: color,
          ),
        ),
        title: Text(req['waste_type_display'] ?? req['waste_type'] ?? '',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(req['date']?.toString() ?? '',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          child: Text(label, style: GoogleFonts.poppins(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
