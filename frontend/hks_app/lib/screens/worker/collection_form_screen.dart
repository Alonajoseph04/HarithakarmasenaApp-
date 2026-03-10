import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CollectionFormScreen extends StatefulWidget {
  final Map<String, dynamic> householdData;
  const CollectionFormScreen({super.key, required this.householdData});
  @override State<CollectionFormScreen> createState() => _CollectionFormScreenState();
}

class _CollectionFormScreenState extends State<CollectionFormScreen> {
  final _api = ApiService();
  final _weightCtrl = TextEditingController();
  final _rateCtrl = TextEditingController(text: '10');
  final _notesCtrl = TextEditingController();
  final _upiOverrideCtrl = TextEditingController();
  String _wasteType = 'plastic';
  late String _paymentMethod;
  int _cleanliness = 3;
  bool _submitting = false;
  bool _showUpi = false;

  @override
  void initState() {
    super.initState();
    // Pre-select household's preferred payment method
    final pref = widget.householdData['preferred_payment'] as String? ?? 'cash';
    _paymentMethod = pref;
    _showUpi = pref == 'upi';
    // Pre-fill UPI ID from household profile
    _upiOverrideCtrl.text = widget.householdData['upi_id'] as String? ?? '';
  }

  String get _effectiveUpiId => _upiOverrideCtrl.text.trim().isNotEmpty
      ? _upiOverrideCtrl.text.trim()
      : 'hks.kerala@upi';

  double get _amount => (double.tryParse(_weightCtrl.text) ?? 0) * (double.tryParse(_rateCtrl.text) ?? 0);

  final List<({String value, String label})> _wasteTypes = [
    (value: 'plastic', label: 'Plastic'),
    (value: 'ewaste', label: 'E-Waste'),
    (value: 'organic', label: 'Organic'),
    (value: 'mixed', label: 'Mixed'),
    (value: 'paper', label: 'Paper'),
    (value: 'glass', label: 'Glass'),
    (value: 'metal', label: 'Metal'),
  ];

  Future<void> _submit() async {
    if (_weightCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter weight')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      // Get worker data
      final worker = await _api.getWorkerMe();
      await _api.createCollection({
        'household': widget.householdData['id'],
        'worker': worker['id'],
        'date': today,
        'waste_type': _wasteType,
        'weight': double.parse(_weightCtrl.text),
        'rate': double.parse(_rateCtrl.text),
        'amount': _amount,
        'cleanliness': _cleanliness,
        'payment_method': _paymentMethod,
        'payment_status': 'paid',
        'notes': _notesCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection recorded successfully!'), backgroundColor: AppTheme.primary));
        context.go('/worker');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.householdData;
    return Scaffold(
      appBar: AppBar(title: const Text('Record Collection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Household info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryLight]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Household Details', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
              Text(h['name'] ?? '-', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.location_on, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Expanded(child: Text(h['address'] ?? '-', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.80)))),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.phone, size: 14, color: Colors.white70),
                const SizedBox(width: 4),
                Text(h['phone'] ?? '-', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withOpacity(0.80))),
              ]),
              const SizedBox(height: 6),
              if ((double.tryParse(h['pending_amount']?.toString() ?? '0') ?? 0.0) > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade300, borderRadius: BorderRadius.circular(8)),
                  child: Text('Pending: Rs ${h['pending_amount']}',
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
            ]),
          ),
          const SizedBox(height: 20),
          // Form fields
          Text('Waste Details', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          // Waste type chips
          Wrap(spacing: 8, runSpacing: 8, children: _wasteTypes.map((t) => ChoiceChip(
            label: Text(t.label),
            selected: _wasteType == t.value,
            onSelected: (_) => setState(() => _wasteType = t.value),
            selectedColor: AppTheme.primary,
            labelStyle: TextStyle(color: _wasteType == t.value ? Colors.white : AppTheme.textDark),
          )).toList()),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(
              controller: _weightCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Weight (kg)', suffixText: 'kg', prefixIcon: Icon(Icons.scale)),
            )),
            const SizedBox(width: 12),
            Expanded(child: TextField(
              controller: _rateCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'Rate (Rs/kg)', prefixIcon: Icon(Icons.currency_rupee)),
            )),
          ]),
          if (_amount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Total Amount', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text('Rs ${_amount.toStringAsFixed(2)}', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ]),
            ),
          ],
          const SizedBox(height: 16),
          Text('Cleanliness Rating', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14)),
          const SizedBox(height: 8),
          Row(children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _cleanliness = i + 1),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                i < _cleanliness ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 36,
              ),
            ),
          ))),
          const SizedBox(height: 16),
          // Payment preference badge
          if (widget.householdData['preferred_payment'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 14, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text('Household prefers ${(widget.householdData['preferred_payment'] as String).toUpperCase()} payment',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
              ]),
            ),
          Text('Payment Method', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _PaymentToggle('Cash', Icons.payments, 'cash', _paymentMethod, (v) => setState(() { _paymentMethod = v; _showUpi = false; }))),
            const SizedBox(width: 10),
            Expanded(child: _PaymentToggle('UPI', Icons.qr_code, 'upi', _paymentMethod, (v) => setState(() { _paymentMethod = v; _showUpi = true; }))),
            const SizedBox(width: 10),
            Expanded(child: _PaymentToggle('Pending', Icons.pending, 'pending', _paymentMethod, (v) => setState(() { _paymentMethod = v; _showUpi = false; }))),
          ]),
          if (_showUpi) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _upiOverrideCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Household UPI ID',
                hintText: 'e.g. householder@okaxis',
                prefixIcon: Icon(Icons.account_balance_wallet),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Column(children: [
              Text('Household scans this QR to pay', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
                child: _amount > 0
                    ? QrImageView(
                        data: 'upi://pay?pa=${Uri.encodeComponent(_effectiveUpiId)}&pn=HKS+Waste&am=${_amount.toStringAsFixed(2)}&cu=INR&tn=WasteCollection',
                        size: 200,
                      )
                    : const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Enter weight to generate QR', textAlign: TextAlign.center),
                      ),
              ),
              const SizedBox(height: 6),
              Text('UPI: $_effectiveUpiId', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
              if (_amount > 0)
                Text('Amount: Rs ${_amount.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ])),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.note)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle),
            label: Text(_submitting ? 'Recording...' : 'Submit Collection'),
            onPressed: _submitting ? null : _submit,
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

class _PaymentToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final String selected;
  final void Function(String) onTap;
  const _PaymentToggle(this.label, this.icon, this.value, this.selected, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onTap(value),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: selected == value ? AppTheme.primary : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: selected == value ? AppTheme.primary : Colors.grey.shade300, width: 1.5),
      ),
      child: Column(children: [
        Icon(icon, color: selected == value ? Colors.white : AppTheme.textLight),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(color: selected == value ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500)),
      ]),
    ),
  );
}
