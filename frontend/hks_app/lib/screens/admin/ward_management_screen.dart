import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class WardManagementScreen extends StatefulWidget {
  const WardManagementScreen({super.key});
  @override
  State<WardManagementScreen> createState() => _WardManagementScreenState();
}

class _WardManagementScreenState extends State<WardManagementScreen> {
  final _api = ApiService();
  List<dynamic> _wards = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final w = await _api.getWards();
      setState(() { _wards = w; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _showDialog([Map<String, dynamic>? existing]) {
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final housesCtrl = TextEditingController(text: existing?['total_houses']?.toString() ?? '');
    final descCtrl = TextEditingController(text: existing?['description'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(existing == null ? 'Add Ward' : 'Edit Ward',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ward Name')),
          const SizedBox(height: 10),
          TextField(controller: housesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Houses')),
          const SizedBox(height: 10),
          TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final data = {
                'name': nameCtrl.text,
                'total_houses': int.tryParse(housesCtrl.text) ?? 0,
                'description': descCtrl.text,
              };
              if (existing == null) {
                await _api.createWard(data);
              } else {
                await _api.updateWard(existing['id'] as int, data);
              }
              _load();
            },
            child: Text(existing == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ward Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog(),
        icon: const Icon(Icons.add_location),
        label: const Text('Add Ward'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _wards.length,
              itemBuilder: (ctx, i) {
                final w = _wards[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(w['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      'Houses: ${w['total_houses']} • Workers: ${w['worker_count']} • Registered: ${w['household_count']}',
                      style: GoogleFonts.poppins(fontSize: 12)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.edit, color: AppTheme.primary),
                          onPressed: () => _showDialog(w)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            await _api.deleteWard(w['id'] as int);
                            _load();
                          }),
                    ]),
                  ),
                );
              },
            ),
    );
  }
}
