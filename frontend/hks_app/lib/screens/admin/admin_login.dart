import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../theme/app_theme.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController(text: 'admin');
  final _passwordCtrl = TextEditingController(text: 'admin@123');
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Language toggle
                  const Align(
                    alignment: Alignment.topRight,
                    child: LangToggleButton(),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.admin_panel_settings, size: 70, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(s.adminLogin, style: GoogleFonts.poppins(
                      fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(s.appName, style: GoogleFonts.poppins(
                      fontSize: 14, color: Colors.white60)),
                  const SizedBox(height: 36),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8))],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _usernameCtrl,
                            decoration: InputDecoration(
                              labelText: s.username,
                              prefixIcon: const Icon(Icons.person),
                            ),
                            validator: (v) => v!.isEmpty ? s.username : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: s.password,
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) => v!.isEmpty ? s.password : null,
                          ),
                          if (auth.error != null) ...[
                            const SizedBox(height: 12),
                            Text(auth.error!, style: const TextStyle(color: AppTheme.error)),
                          ],
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: auth.isLoading ? null : () async {
                              if (_formKey.currentState!.validate()) {
                                final ok = await auth.loginWorkerOrAdmin(
                                    _usernameCtrl.text, _passwordCtrl.text);
                                if (ok && mounted) context.go('/admin');
                              }
                            },
                            child: auth.isLoading
                                ? const SizedBox(width: 24, height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(s.login),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.go('/'),
                            child: Text(s.backToRoleSelect),
                          ),
                        ],
                      ),
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
