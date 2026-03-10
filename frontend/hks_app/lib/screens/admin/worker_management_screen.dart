import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class WorkerManagementScreen extends StatefulWidget {
  const WorkerManagementScreen({super.key});
  @override
  State<WorkerManagementScreen> createState() => _WorkerManagementScreenState();
}

class _WorkerManagementScreenState extends State<WorkerManagementScreen> {
  final _api = ApiService();
  List<dynamic> _workers = [];
  List<dynamic> _wards = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final workers = await _api.getWorkers();
      final wards = await _api.getWards();
      setState(() { _workers = workers; _wards = wards; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  void _showAddWorkerDialog([Map<String, dynamic>? existing]) {
    final fnCtrl = TextEditingController(text: existing?['user']?['first_name'] ?? '');
    final lnCtrl = TextEditingController(text: existing?['user']?['last_name'] ?? '');
    final idCtrl = TextEditingController(text: existing?['worker_id'] ?? '');
    final passCtrl = TextEditingController(text: 'worker@123');
    int? wardId = existing?['ward']?['id'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(existing == null ? 'Add Worker' : 'Edit Worker',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: fnCtrl, decoration: const InputDecoration(labelText: 'First Name')),
              const SizedBox(height: 10),
              TextField(controller: lnCtrl, decoration: const InputDecoration(labelText: 'Last Name')),
              const SizedBox(height: 10),
              TextField(controller: idCtrl, decoration: const InputDecoration(labelText: 'Worker ID')),
              const SizedBox(height: 10),
              if (existing == null) TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password')),
              if (existing == null) const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: wardId,
                hint: const Text('Select Ward'),
                items: _wards.map((w) => DropdownMenuItem<int>(
                  value: w['id'] as int,
                  child: Text(w['name'].toString()),
                )).toList(),
                onChanged: (v) => ss(() => wardId = v),
                decoration: const InputDecoration(labelText: 'Assign Ward'),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  if (existing == null) {
                    await _api.createWorker({
                      'worker_id': idCtrl.text,
                      'ward_id': wardId,
                      'is_active': true,
                      'user_data': {
                        'first_name': fnCtrl.text, 'last_name': lnCtrl.text,
                        'password': passCtrl.text,
                      },
                    });
                  } else {
                    await _api.updateWorker(existing['id'] as int, {'ward_id': wardId});
                  }
                  _load();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString().substring(0, 80)}')));
                }
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Worker Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWorkerDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Worker'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _workers.isEmpty
                  ? const Center(child: Text('No workers yet'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _workers.length,
                      itemBuilder: (ctx, i) {
                        final w = _workers[i];
                        final user = w['user'] ?? {};
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.primary,
                              child: Text(w['worker_id'].toString().substring(0,2),
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            title: Text('${user['first_name']} ${user['last_name']}',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            subtitle: Text('ID: ${w['worker_id']} • ${w['ward']?['name'] ?? 'No ward'}',
                                style: GoogleFonts.poppins(fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: AppTheme.primary),
                                    onPressed: () => _showAddWorkerDialog(w)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      await _api.deleteWorker(w['id'] as int);
                                      _load();
                                    }),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
