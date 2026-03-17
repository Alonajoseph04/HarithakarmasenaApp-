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
    Navigator.pop(context);
    try {
      await _api.updateHousehold(household['id'] as int, {});
      await _load();
      final refreshed = _households.firstWhere(
        (h) => h['id'] == household['id'], orElse: () => household);
      if (mounted) _showQR(refreshed);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate QR: $e'), backgroundColor: Colors.red));
    }
  }

  void _showAddDialog([Map<String, dynamic>? existing]) {
    final nameCtrl  = TextEditingController(text: existing?['name'] ?? '');
    final addrCtrl  = TextEditingController(text: existing?['address'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final feeCtrl   = TextEditingController(
      text: existing?['monthly_fee']?.toString() ?? '100');
    // Login fields — only shown for new households
    final fnCtrl    = TextEditingController();
    final lnCtrl    = TextEditingController();
    final userCtrl  = TextEditingController();
    final passCtrl  = TextEditingController(text: 'hks@1234');
    int? wardId     = existing?['ward']?['id'];
    bool obscurePass = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'Add Household' : 'Edit Household',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // ── Household details ──────────────────────────────────
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Household Name *',
                  prefixIcon: Icon(Icons.home),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  hintText: 'e.g. 9876543210',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: addrCtrl,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
              ),
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
                decoration: const InputDecoration(
                  labelText: 'Assign Ward',
                  prefixIcon: Icon(Icons.location_city),
                ),
                items: _wards.map((w) => DropdownMenuItem<int>(
                  value: w['id'] as int, child: Text(w['name']))).toList(),
                onChanged: (v) => ss(() => wardId = v),
              ),

              // ── App login account — only for new households ────────
              if (existing == null) ...[
                const SizedBox(height: 18),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    const Icon(Icons.account_circle, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 6),
                    Text('App Login Account',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppTheme.primary)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: Text(
                    'This creates a login account for the household to use the app. '
                    'If Username is left blank, the phone number is used as username.',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight),
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextField(
                    controller: fnCtrl,
                    decoration: const InputDecoration(
                        labelText: 'First Name', prefixIcon: Icon(Icons.person)),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: lnCtrl,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  )),
                ]),
                const SizedBox(height: 10),
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username (optional)',
                    prefixIcon: Icon(Icons.alternate_email),
                    hintText: 'Leave blank to use phone',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePass ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => ss(() => obscurePass = !obscurePass),
                    ),
                  ),
                ),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final fee = double.tryParse(feeCtrl.text.trim()) ?? 100.0;
                final data = <String, dynamic>{
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'address': addrCtrl.text.trim(),
                  'ward_id': wardId,
                  'monthly_fee': fee,
                };
                // Attach user_data only when creating
                if (existing == null) {
                  data['user_data'] = {
                    'first_name': fnCtrl.text.trim().isNotEmpty
                        ? fnCtrl.text.trim()
                        : nameCtrl.text.trim(),
                    'last_name': lnCtrl.text.trim(),
                    'password': passCtrl.text.trim().isNotEmpty
                        ? passCtrl.text.trim()
                        : 'hks@1234',
                    if (userCtrl.text.trim().isNotEmpty)
                      'username': userCtrl.text.trim(),
                  };
                }
                try {
                  if (existing == null) {
                    await _api.createHousehold(data);
                  } else {
                    await _api.updateHousehold(existing['id'] as int, data);
                  }
                  _load();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(existing == null
                          ? '✓ Household added with login account'
                          : '✓ Household updated'),
                      backgroundColor: Colors.green,
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
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
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(household['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (qrCode.isEmpty) ...[
              const Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
              const SizedBox(height: 12),
              Text('No QR code assigned yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
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
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10)],
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
                child: SelectableText(qrCode,
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 4),
              Text('Scan this QR to record collection',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
            ],
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Close'))],
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
              child: _households.isEmpty
                  ? const Center(child: Text('No households yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _households.length,
                      itemBuilder: (ctx, i) {
                        final h = _households[i];
                        final hasAccount = h['has_user_account'] == true;
                        final loginUser = h['login_username']?.toString() ?? '';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: hasAccount
                                  ? Colors.green.shade200
                                  : Colors.orange.shade200,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: hasAccount ? Colors.green : AppTheme.secondary,
                              child: Text(
                                h['name'].toString().substring(0, 1),
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            title: Text(h['name'].toString(),
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${h['phone'] ?? '-'} • ${h['ward']?['name'] ?? 'No ward'} • Rs ${h['monthly_fee'] ?? 100}/mo',
                                  style: GoogleFonts.poppins(fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(children: [
                                  Icon(
                                    hasAccount ? Icons.check_circle : Icons.person_off,
                                    size: 12,
                                    color: hasAccount ? Colors.green : Colors.orange,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    hasAccount
                                        ? 'Login: $loginUser'
                                        : 'No app account',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: hasAccount ? Colors.green.shade700 : Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ]),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              IconButton(
                                icon: const Icon(Icons.qr_code, color: AppTheme.primary),
                                onPressed: () => _showQR(h),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: AppTheme.primary),
                                onPressed: () => _showAddDialog(h),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Delete Household?'),
                                      content: Text(
                                          'This will also delete the linked login account for ${h['name']}.'),
                                      actions: [
                                        TextButton(
                                            onPressed: () => Navigator.pop(c, false),
                                            child: const Text('Cancel')),
                                        ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            onPressed: () => Navigator.pop(c, true),
                                            child: const Text('Delete')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _api.deleteHousehold(h['id'] as int);
                                    _load();
                                  }
                                },
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
