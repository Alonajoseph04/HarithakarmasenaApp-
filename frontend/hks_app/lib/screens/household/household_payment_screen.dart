import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

/// Shows UPI QR for scanning by household — provided by worker during payment
class HouseholdPaymentScreen extends StatefulWidget {
  const HouseholdPaymentScreen({super.key});
  @override
  State<HouseholdPaymentScreen> createState() => _HouseholdPaymentScreenState();
}

class _HouseholdPaymentScreenState extends State<HouseholdPaymentScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _upiIdCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String? _upiDeepLink;
  bool _scanning = false;

  static const _commonApps = [
    (label: 'GPay', upiId: 'gpay@okaxis', color: Colors.blue),
    (label: 'PhonePe', upiId: 'phonepeupi@ybl', color: Colors.deepPurple),
    (label: 'Paytm', upiId: 'paytm@paytm', color: Colors.blue),
    (label: 'BHIM', upiId: 'bhim@upi', color: Colors.orange),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  String _buildUpiLink(String upiId, double amount) {
    final enc = Uri.encodeComponent;
    return 'upi://pay?pa=${enc(upiId)}&pn=${enc('HKS Collection')}&am=${amount.toStringAsFixed(2)}&cu=INR&tn=${enc('Waste Collection Payment')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Payment'),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [Tab(text: 'Generate UPI QR'), Tab(text: 'Scan Worker QR')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // TAB 1 — Generate a QR for the worker to scan
          _buildGenerateTab(),
          // TAB 2 — Scan the worker's UPI QR code
          _buildScanTab(),
        ],
      ),
    );
  }

  Widget _buildGenerateTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(children: [
            const Icon(Icons.qr_code, color: Colors.blue, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Enter the worker\'s UPI ID and amount to generate a QR code for them to scan.',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue.shade800),
            )),
          ]),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _upiIdCtrl,
          decoration: const InputDecoration(
            labelText: 'Worker UPI ID',
            hintText: 'e.g. worker@okaxis',
            prefixIcon: Icon(Icons.account_balance_wallet),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _amountCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount (Rs)',
            prefixIcon: Icon(Icons.currency_rupee),
          ),
        ),
        const SizedBox(height: 14),
        // Common UPI shortcuts
        Text('Quick Select', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _commonApps.map((app) => GestureDetector(
            onTap: () { _upiIdCtrl.text = app.upiId; setState(() {}); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: app.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: app.color.withOpacity(0.3)),
              ),
              child: Text(app.label, style: GoogleFonts.poppins(fontSize: 12, color: app.color, fontWeight: FontWeight.w600)),
            ),
          )).toList(),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          icon: const Icon(Icons.qr_code_2),
          label: const Text('Generate QR'),
          onPressed: () {
            final upi = _upiIdCtrl.text.trim();
            final amt = double.tryParse(_amountCtrl.text.trim()) ?? 0;
            if (upi.isEmpty || amt <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid UPI ID and amount')),
              );
              return;
            }
            setState(() => _upiDeepLink = _buildUpiLink(upi, amt));
          },
        ),
        if (_upiDeepLink != null) ...[
          const SizedBox(height: 28),
          Center(child: Column(children: [
            Text('Show this to the worker to scan:', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
              ),
              child: QrImageView(data: _upiDeepLink!, size: 220, version: QrVersions.auto),
            ),
            const SizedBox(height: 12),
            Text('UPI: ${_upiIdCtrl.text}', style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textLight)),
            Text('Rs ${_amountCtrl.text}',
                style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ])),
        ],
      ],
    );
  }

  Widget _buildScanTab() {
    if (!_scanning) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.qr_code_scanner, size: 72, color: AppTheme.primary),
          const SizedBox(height: 16),
          Text('Scan the worker\'s UPI QR code\nto make a payment',
              style: GoogleFonts.poppins(fontSize: 15, color: AppTheme.textLight),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.camera_alt),
            label: const Text('Open Scanner'),
            onPressed: () => setState(() => _scanning = true),
          ),
          const SizedBox(height: 12),
          Text('Camera works on mobile. Use the "Generate QR" tab on web.',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
        ]),
      );
    }
    return Stack(
      children: [
        MobileScanner(
          onDetect: (capture) {
            final barcode = capture.barcodes.first;
            final raw = barcode.rawValue;
            if (raw != null && mounted) {
              setState(() => _scanning = false);
              _showScanResult(raw);
            }
          },
        ),
        Positioned(
          bottom: 30,
          left: 0, right: 0,
          child: Center(
            child: TextButton.icon(
              icon: const Icon(Icons.close, color: Colors.white),
              label: Text('Cancel', style: GoogleFonts.poppins(color: Colors.white)),
              onPressed: () => setState(() => _scanning = false),
            ),
          ),
        ),
      ],
    );
  }

  void _showScanResult(String qrValue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle, size: 48, color: AppTheme.primary),
          const SizedBox(height: 12),
          Text('QR Scanned', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Open your UPI app to complete the payment:',
              style: GoogleFonts.poppins(color: AppTheme.textLight), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: Text(qrValue,
                style: GoogleFonts.sourceCodePro(fontSize: 11, color: AppTheme.textDark),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ]),
      ),
    );
  }
}
