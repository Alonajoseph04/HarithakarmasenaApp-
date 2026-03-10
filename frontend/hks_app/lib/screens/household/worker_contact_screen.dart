import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class WorkerContactScreen extends StatefulWidget {
  const WorkerContactScreen({super.key});
  @override
  State<WorkerContactScreen> createState() => _WorkerContactScreenState();
}

class _WorkerContactScreenState extends State<WorkerContactScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _household;
  List<dynamic> _wardWorkers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final h = await _api.getHouseholdMe();
      List<dynamic> workers = [];
      if (h['ward'] != null) {
        final wardId = h['ward']['id'] as int;
        workers = await _api.getWorkers();
        workers = workers.where((w) => w['ward']?['id'] == wardId).toList();
      }
      setState(() { _household = h; _wardWorkers = workers; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Ward Workers')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.error)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Ward info banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
                          const Icon(Icons.location_city, color: Colors.white, size: 32),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Your Ward', style: GoogleFonts.poppins(color: Colors.white60, fontSize: 12)),
                            Text(_household?['ward']?['name'] ?? '-',
                                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      if (_wardWorkers.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(children: [
                              const Icon(Icons.person_off, size: 56, color: Colors.grey),
                              const SizedBox(height: 10),
                              Text('No workers assigned to your ward yet.',
                                  style: GoogleFonts.poppins(color: AppTheme.textLight), textAlign: TextAlign.center),
                            ]),
                          ),
                        )
                      else ...[
                        Text('Assigned Workers', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 10),
                        ..._wardWorkers.map((w) => _WorkerCard(worker: w)),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  const _WorkerCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    final user = worker['user'] as Map<String, dynamic>? ?? {};
    final name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    final phone = user['phone'] as String? ?? '';
    final workerId = worker['worker_id'] as String? ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primary.withOpacity(0.12),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'W',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isNotEmpty ? name : 'Worker', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('ID: $workerId', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.phone, size: 14, color: AppTheme.primary),
                const SizedBox(width: 4),
                Text(phone, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ]),
            ],
          ])),
          if (phone.isNotEmpty)
            Column(children: [
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: AppTheme.primary),
                tooltip: 'Copy number',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: phone));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone number copied'), duration: Duration(seconds: 2)),
                  );
                },
              ),
              const Text('Copy', style: TextStyle(fontSize: 10, color: AppTheme.primary)),
            ]),
        ]),
      ),
    );
  }
}
