import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/theme_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final backendType = ref.watch(backendTypeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Employee Profile',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar Card
          Center(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: user != null ? NetworkImage(user.photoUrl) : null,
                        child: user == null ? const Icon(Icons.person, size: 48, color: AppColors.primary) : null,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.badge, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Alex Morgan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.designation ?? 'Senior Software Engineer',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                Chip(
                  label: Text(
                    user?.id ?? 'EMP-8842',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // User Info Section
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                  title: Text('Email Address', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondaryLight)),
                  subtitle: Text(user?.email ?? 'alex.morgan@acmeglobal.com', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const Icon(Icons.business_outlined, color: AppColors.primary),
                  title: Text('Department', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondaryLight)),
                  subtitle: Text(user?.department ?? 'Engineering & Technology', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const Icon(Icons.supervisor_account_outlined, color: AppColors.primary),
                  title: Text('Reporting Manager', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondaryLight)),
                  subtitle: Text('${user?.reportingManagerName} (${user?.reportingManagerEmail})', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Settings & Switchers
          Text('Settings & Configuration', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                  title: Text('Dark Mode', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  subtitle: Text('Enable low-light theme', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondaryLight)),
                  value: themeMode == ThemeMode.dark ||
                      (themeMode == ThemeMode.system && isDark),
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).state =
                        val ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined, color: AppColors.primary),
                  title: Text('Backend Repository Engine', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    backendType == BackendType.mock
                        ? 'Local Mock Repository (Offline Demo)'
                        : 'Google Apps Script / Sheets API',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                  trailing: DropdownButton<BackendType>(
                    value: backendType,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: BackendType.mock,
                        child: Text('Mock Engine'),
                      ),
                      DropdownMenuItem(
                        value: BackendType.googleSheets,
                        child: Text('Google Sheets API'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(backendTypeProvider.notifier).state = val;
                      }
                    },
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded, color: AppColors.primary),
                  title: Text('Help & Support FAQ', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('ERMS Help & Support', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        content: Text(
                          'For urgent requests or manager escalations, please contact the IT Service Desk at support@acmeglobal.com or call ext 4432.',
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('Close', style: GoogleFonts.plusJakartaSans(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Logout Button
          CustomButton(
            text: 'Log Out',
            isOutlined: true,
            backgroundColor: AppColors.statusRejected,
            textColor: AppColors.statusRejected,
            icon: Icons.logout_rounded,
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
            },
          ),
        ],
      ),
    );
  }
}
