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
  final _notesCtrl = TextEditingController();
  final _upiOverrideCtrl = TextEditingController();
  String _wasteType = 'organic';
  late String _paymentMethod;
  int _cleanliness = 3;
  bool _submitting = false;
  bool _showUpi = false;

  // The collection amount is fixed — comes from household monthly_fee
  double get _amount {
    final fee = widget.householdData['monthly_fee'];
    return double.tryParse(fee?.toString() ?? '0') ?? 0.0;
  }

  double get _weight => double.tryParse(_weightCtrl.text) ?? 0.0;

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

  final List<({String value, String label, IconData icon})> _wasteTypes = [
    (value: 'organic',  label: 'Organic',  icon: Icons.eco),
    (value: 'plastic',  label: 'Plastic',  icon: Icons.recycling),
    (value: 'paper',    label: 'Paper',    icon: Icons.description),
    (value: 'glass',    label: 'Glass',    icon: Icons.local_drink),
    (value: 'metal',    label: 'Metal',    icon: Icons.hardware),
    (value: 'ewaste',   label: 'E-Waste',  icon: Icons.electrical_services),
    (value: 'mixed',    label: 'Mixed',    icon: Icons.delete),
  ];

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final worker = await _api.getWorkerMe();
      await _api.createCollection({
        'household': widget.householdData['id'],
        'worker': worker['id'],
        'date': today,
        'waste_type': _wasteType,
        // weight is optional for tracking; amount comes from monthly_fee
        'weight': _weight,
        'rate': 0,
        'amount': _amount,
        'cleanliness': _cleanliness,
        'payment_method': _paymentMethod,
        'payment_status': _paymentMethod == 'pending' ? 'pending' : 'paid',
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

          // ── Household info ──
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
            ]),
          ),
          const SizedBox(height: 16),

          // ── Collection amount (fixed from monthly_fee) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.currency_rupee, color: AppTheme.primary, size: 28),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Collection Amount (Ward Fee)', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight)),
                Text(
                  'Rs ${_amount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ]),
              const Spacer(),
              const Icon(Icons.lock, size: 18, color: AppTheme.textLight),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Waste type ──
          Text('Waste Type', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _wasteTypes.map((t) => ChoiceChip(
              avatar: Icon(t.icon, size: 16, color: _wasteType == t.value ? Colors.white : AppTheme.textLight),
              label: Text(t.label),
              selected: _wasteType == t.value,
              onSelected: (_) => setState(() => _wasteType = t.value),
              selectedColor: AppTheme.primary,
              labelStyle: TextStyle(color: _wasteType == t.value ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500),
            )).toList(),
          ),
          const SizedBox(height: 16),

          // ── Weight input ──
          Text('Waste Weight (optional)', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              hintText: 'e.g. 2.5',
              suffixText: 'kg',
              prefixIcon: const Icon(Icons.scale),
              suffixIcon: _weight > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${_weight.toStringAsFixed(1)} kg',
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.w600)),
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Text('Note: Weight is for tracking only. Collection fee is fixed at Rs ${_amount.toStringAsFixed(0)}.',
              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textLight, fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),

          // ── Cleanliness rating ──
          Text('Cleanliness Rating', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 15)),
          const SizedBox(height: 8),
          Row(children: List.generate(5, (i) => GestureDetector(
            onTap: () => setState(() => _cleanliness = i + 1),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                i < _cleanliness ? Icons.star_rounded : Icons.star_outline_rounded,
                color: Colors.amber,
                size: 38,
              ),
            ),
          ))),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_cleanliness],
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight),
            ),
          ),
          const SizedBox(height: 20),

          // ── Payment method ──
          if (widget.householdData['preferred_payment'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 14, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text('Preferred: ${(widget.householdData['preferred_payment'] as String).toUpperCase()}',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
              ]),
            ),
          Text('Payment Method', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _PaymentToggle('Cash', Icons.payments, 'cash', _paymentMethod,
                (v) => setState(() { _paymentMethod = v; _showUpi = false; }))),
            const SizedBox(width: 10),
            Expanded(child: _PaymentToggle('UPI', Icons.qr_code, 'upi', _paymentMethod,
                (v) => setState(() { _paymentMethod = v; _showUpi = true; }))),
            const SizedBox(width: 10),
            Expanded(child: _PaymentToggle('Pending', Icons.pending, 'pending', _paymentMethod,
                (v) => setState(() { _paymentMethod = v; _showUpi = false; }))),
          ]),

          // ── UPI QR ──
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
                child: QrImageView(
                  data: 'upi://pay?pa=${Uri.encodeComponent(_effectiveUpiId)}&pn=HKS+Waste&am=${_amount.toStringAsFixed(2)}&cu=INR&tn=WasteCollection',
                  size: 200,
                ),
              ),
              const SizedBox(height: 6),
              Text('UPI: $_effectiveUpiId', style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textLight)),
              Text('Amount: Rs ${_amount.toStringAsFixed(0)}',
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle),
              label: Text(_submitting ? 'Recording...' : 'Confirm Collection — Rs ${_amount.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _submitting ? null : _submit,
            ),
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
