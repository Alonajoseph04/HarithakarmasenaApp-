import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class HouseholdManagementScreen extends StatefulWidget {
  const HouseholdManagementScreen({super.key});
  @override
  State<HouseholdManagementScreen> createState() => _HouseholdManagementScreenState();
}

class _HouseholdManagementScreenState extends State<HouseholdManagementScreen> {
  final _api = ApiService();
  List<dynamic> _households = [];
  List<dynamic> _wards = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final h = await _api.getHouseholds();
      final w = await _api.getWards();
      setState(() { _households = h; _wards = w; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  /// Trigger backend to assign a QR code by patching with empty data
  Future<void> _generateQr(Map<String, dynamic> household) async {
    Navigator.pop(context); // close old dialog
    try {
      await _api.updateHousehold(household['id'] as int, {});
      await _load();
      // Find refreshed data and show updated dialog
      final refreshed = _households.firstWhere(
        (h) => h['id'] == household['id'], orElse: () => household);
      if (mounted) _showQR(refreshed);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate QR: $e'), backgroundColor: Colors.red));
    }
  }

  void _showAddDialog([Map<String, dynamic>? existing]) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final addrCtrl = TextEditingController(text: existing?['address'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final feeCtrl = TextEditingController(
      text: existing?['monthly_fee']?.toString() ?? '100',
    );
    int? wardId = existing?['ward']?['id'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'Add Household' : 'Edit Household',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Household Name')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number'), keyboardType: TextInputType.phone),
              const SizedBox(height: 10),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address'), maxLines: 2),
              const SizedBox(height: 10),
              TextField(
                controller: feeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Fee (Rs)',
                  prefixIcon: Icon(Icons.currency_rupee),
                  hintText: '100',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: wardId,
                hint: const Text('Select Ward'),
                decoration: const InputDecoration(labelText: 'Assign Ward'),
                items: _wards.map((w) => DropdownMenuItem<int>(
                  value: w['id'] as int, child: Text(w['name']),
                )).toList(),
                onChanged: (v) => ss(() => wardId = v),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final fee = double.tryParse(feeCtrl.text.trim()) ?? 100.0;
                final data = {
                  'name': nameCtrl.text, 'phone': phoneCtrl.text,
                  'address': addrCtrl.text, 'ward_id': wardId,
                  'monthly_fee': fee,
                };
                try {
                  if (existing == null) {
                    await _api.createHousehold(data);
                  } else {
                    await _api.updateHousehold(existing['id'] as int, data);
                  }
                  _load();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString().substring(0, 80)}')));
                  }
                }
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQR(Map<String, dynamic> household) {
    final qrCode = (household['qr_code'] ?? '').toString().trim();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(household['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (qrCode.isEmpty) ...[
              const Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'No QR code assigned yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Generate QR Code'),
                onPressed: () => _generateQr(household),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10)],
                ),
                child: QrImageView(data: qrCode, version: QrVersions.auto, size: 200),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(qrCode, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              Text('Scan this QR to record collection', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
            ],
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Household Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.add_home),
        label: const Text('Add Household'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _households.length,
                itemBuilder: (ctx, i) {
                  final h = _households[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.secondary,
                        child: Text(h['name'].toString().substring(0, 1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(h['name'].toString(), style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      subtitle: Text('${h['phone']} • ${h['ward']?['name'] ?? 'No ward'} • Rs ${h['monthly_fee'] ?? 100}/mo\n${h['address']}',
                          style: GoogleFonts.poppins(fontSize: 11), maxLines: 2),
                      isThreeLine: true,
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(icon: const Icon(Icons.qr_code, color: AppTheme.primary),
                            onPressed: () => _showQR(h)),
                        IconButton(icon: const Icon(Icons.edit, color: AppTheme.primary),
                            onPressed: () => _showAddDialog(h)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await _api.deleteHousehold(h['id'] as int);
                              _load();
                            }),
                      ]),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
