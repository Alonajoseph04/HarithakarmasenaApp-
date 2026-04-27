import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});
  @override State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _api = ApiService();
  MobileScannerController? _controller;
  bool _scanned = false;
  bool _manualLoading = false; // shows overlay while manual lookup runs

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    setState(() => _scanned = true);
    _controller?.stop();

    final qrCode = barcode!.rawValue!;
    try {
      final household = await _api.getHouseholdByQr(qrCode);
      if (mounted) {
        context.push('/worker/collect', extra: household);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Household not found for this QR code'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _scanned = false);
        _controller?.start();
      }
    }
  }

  Future<void> _manualLookup(String qrCode) async {
    if (qrCode.isEmpty) return;
    setState(() => _manualLoading = true);
    try {
      // Try exact QR code first; if that fails try searching by house code
      Map<String, dynamic> household;
      try {
        household = await _api.getHouseholdByQr(qrCode);
      } catch (_) {
        // Try by_code fallback (forgiving search by name/code)
        household = await _api.getHouseholdByCode(qrCode);
      }
      if (mounted) {
        setState(() => _manualLoading = false);
        context.push('/worker/collect', extra: household);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _manualLoading = false);
        final msg = e.toString().contains('404') || e.toString().contains('not found')
            ? 'No household found for "$qrCode". Check the code and try again.'
            : 'Error looking up household: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showManualDialog() {
    final ctrl = TextEditingController();
    final s = context.read<LanguageProvider>().strings;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.enterQrCode),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                hintText: 'HKS-A1B2C3D4E5',
                prefixIcon: Icon(Icons.qr_code),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the QR code printed on the household card (e.g. HKS-A1B2C3D4E5)',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              final code = ctrl.text.trim();
              Navigator.pop(context);
              _manualLookup(code);
            },
            child: Text(s.submit2),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.scanQr),
        actions: const [LangToggleButton()],
      ),
      body: Stack(children: [
        MobileScanner(controller: _controller!, onDetect: _onDetect),

        // QR scan overlay frame
        Center(
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.secondary, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // Bottom instruction + manual entry button
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: Column(children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                s.pointCamera,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.keyboard, color: Colors.white70),
              label: Text(s.manualEntry, style: GoogleFonts.poppins(color: Colors.white70)),
              onPressed: _manualLoading ? null : _showManualDialog,
            ),
          ]),
        ),

        // Loading overlay for manual lookup
        if (_manualLoading)
          Container(
            color: Colors.black45,
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Looking up household…'),
                  ]),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
