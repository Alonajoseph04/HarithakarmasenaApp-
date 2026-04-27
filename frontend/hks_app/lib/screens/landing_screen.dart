import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LanguageProvider>().strings;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Language toggle at top-right
                const Align(
                  alignment: Alignment.topRight,
                  child: LangToggleButton(),
                ),
                const SizedBox(height: 8),
                // Logo
                Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.recycling, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(s.appName,
                    style: GoogleFonts.poppins(
                        fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(s.appSubtitle,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                    textAlign: TextAlign.center),
                const SizedBox(height: 56),
                Text(s.selectRole,
                    style: GoogleFonts.poppins(fontSize: 15, color: Colors.white60)),
                const SizedBox(height: 20),
                _RoleButton(
                  icon: Icons.admin_panel_settings,
                  label: s.roleAdmin,
                  subtitle: s.roleAdminSub,
                  onTap: () => context.go('/admin/login'),
                ),
                const SizedBox(height: 14),
                _RoleButton(
                  icon: Icons.work,
                  label: s.roleWorker,
                  subtitle: s.roleWorkerSub,
                  onTap: () => context.go('/worker/login'),
                ),
                const SizedBox(height: 14),
                _RoleButton(
                  icon: Icons.home,
                  label: s.roleHousehold,
                  subtitle: s.roleHouseholdSub,
                  onTap: () => context.go('/household/login'),
                ),
                const SizedBox(height: 40),
                Text(s.keralaMunicipality,
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white38)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon, required this.label,
    required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text(subtitle, style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.white60)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }
}
