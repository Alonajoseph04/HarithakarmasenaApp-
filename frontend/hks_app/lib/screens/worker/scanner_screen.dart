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
        context.go('/worker/collect', extra: household);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Household not found for this QR code'), backgroundColor: Colors.red));
        setState(() => _scanned = false);
        _controller?.start();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.scanQr),
        actions: [const LangToggleButton()],
      ),
      body: Stack(children: [
        MobileScanner(controller: _controller!, onDetect: _onDetect),
        // Overlay
        Center(
          child: Container(
            width: 260, height: 260,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.secondary, width: 3),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        // Bottom instruction
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
            // Manual QR entry
            TextButton.icon(
              icon: const Icon(Icons.keyboard, color: Colors.white70),
              label: Text(s.manualEntry, style: GoogleFonts.poppins(color: Colors.white70)),
              onPressed: () {
                final ctrl = TextEditingController();
                showDialog(context: context, builder: (_) => AlertDialog(
                  title: Text(s.enterQrCode),
                  content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'HKS-XXXXXXXXXX')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        if (ctrl.text.isNotEmpty) {
                          try {
                            final household = await _api.getHouseholdByQr(ctrl.text);
                            if (mounted) context.go('/worker/collect', extra: household);
                          } catch (_) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.noData)));
                          }
                        }
                      },
                      child: Text(s.submit2),
                    ),
                  ],
                ));
              },
            ),
          ]),
        ),
      ]),
    );
  }
}
