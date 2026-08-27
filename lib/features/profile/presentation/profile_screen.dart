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
                        child: user != null
                            ? ClipOval(
                                child: Image.network(
                                  user.photoUrl,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              )
                            : const Icon(Icons.person, size: 48, color: AppColors.primary),
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
                  user?.name ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.designation ?? '',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 10),
                Chip(
                  label: Text(
                    user?.id ?? '',
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
                  subtitle: Text(user?.email ?? '', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const Icon(Icons.business_outlined, color: AppColors.primary),
                  title: Text('Department', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondaryLight)),
                  subtitle: Text(user?.department ?? '', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const Icon(Icons.supervisor_account_outlined, color: AppColors.primary),
                  title: Text('Reporting Manager', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondaryLight)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.reportingManagerName ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.reportingManagerEmail ?? '',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_sync_outlined, color: AppColors.primary),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Backend Repository Engine',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              backendType == BackendType.mock
                                  ? 'Local Mock Repository (Offline Demo)'
                                  : backendType == BackendType.googleSheets
                                      ? 'Google Apps Script / Sheets API'
                                      : 'Firebase Authentication & Firestore',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<BackendType>(
                            value: backendType,
                            underline: const SizedBox(),
                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            style: GoogleFonts.plusJakartaSans(
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: BackendType.mock,
                                child: Text('Mock Engine'),
                              ),
                              DropdownMenuItem(
                                value: BackendType.googleSheets,
                                child: Text('Google Sheets API'),
                              ),
                              DropdownMenuItem(
                                value: BackendType.firebase,
                                child: Text('Firebase Engine'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(backendTypeProvider.notifier).state = val;
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
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
                          'For urgent requests or manager escalations, please contact the System Administrator.',
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
