import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_theme.dart';

class HouseholdLoginScreen extends StatefulWidget {
  const HouseholdLoginScreen({super.key});
  @override
  State<HouseholdLoginScreen> createState() => _HouseholdLoginScreenState();
}

class _HouseholdLoginScreenState extends State<HouseholdLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _otpSent = false;
  bool _isDebugMode = false;  // set to true when server returns demo_otp
  String? _demoOtp;           // only populated in DEBUG mode

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF004D40), AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.topRight,
                    child: LangToggleButton(),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.home, size: 70, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(s.householdLogin,
                      style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(s.enterRegPhone,
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60)),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        // Phone Field
                        TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          enabled: !_otpSent,
                          decoration: InputDecoration(
                            labelText: s.phone,
                            prefixIcon: const Icon(Icons.phone),
                            filled: true,
                            fillColor: _otpSent ? Colors.grey.shade50 : Colors.white,
                          ),
                        ),

                        // OTP sent confirmation
                        if (_otpSent) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${s.otpSentTo} ${_phoneCtrl.text}',
                                          style: GoogleFonts.poppins(
                                              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                                      // Debug OTP hint shown ONLY when server sends demo_otp
                                      if (_isDebugMode && _demoOtp != null)
                                        Text('DEBUG OTP: $_demoOtp',
                                            style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange.shade700)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        // OTP Field
                        if (_otpSent) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _otpCtrl,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 10),
                            decoration: InputDecoration(
                              labelText: s.enterOtp,
                              counterText: '',
                              prefixIcon: const Icon(Icons.lock_clock),
                            ),
                          ),
                        ],

                        if (auth.error != null) ...[
                          const SizedBox(height: 10),
                          Text(auth.error!,
                              style: const TextStyle(color: AppTheme.error),
                              textAlign: TextAlign.center),
                        ],

                        const SizedBox(height: 20),

                        if (!_otpSent)
                          ElevatedButton(
                            onPressed: auth.isLoading ? null : () async {
                              if (_phoneCtrl.text.trim().isEmpty) return;
                              final res = await auth.sendOtp(_phoneCtrl.text.trim());
                              if (res != null && mounted) {
                                setState(() {
                                  _otpSent = true;
                                  // Server only returns demo_otp in DEBUG mode (no Twilio)
                                  _demoOtp = res['demo_otp']?.toString();
                                  _isDebugMode = _demoOtp != null;
                                });
                              }
                            },
                            child: auth.isLoading
                                ? const SizedBox(width: 24, height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(s.sendOtp),
                          )
                        else ...[
                          ElevatedButton(
                            onPressed: auth.isLoading ? null : () async {
                              final ok = await auth.verifyOtp(
                                  _phoneCtrl.text.trim(), _otpCtrl.text.trim());
                              if (ok && mounted) context.go('/household');
                            },
                            child: auth.isLoading
                                ? const SizedBox(width: 24, height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(s.verifyOtpLogin),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => setState(() {
                              _otpSent = false;
                              _demoOtp = null;
                              _isDebugMode = false;
                              _otpCtrl.clear();
                            }),
                            child: Text(s.changePhone),
                          ),
                        ],

                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/'),
                          child: Text(s.backToRoleSelect),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
