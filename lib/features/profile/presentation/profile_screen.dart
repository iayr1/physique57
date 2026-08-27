import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        elevation: 0,
        title: Text(
          'My Profile & Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 19),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Digital Employee ID Card
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.fitness_center_rounded, color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PHYSIQUE 57',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: user?.isAdmin == true ? Colors.purple.withValues(alpha: 0.3) : Colors.blue.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: user?.isAdmin == true ? Colors.purpleAccent : Colors.lightBlueAccent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        user?.isAdmin == true ? 'ADMINISTRATOR' : 'STAFF MEMBER',
                        style: GoogleFonts.outfit(
                          color: user?.isAdmin == true ? Colors.purple[100] : Colors.lightBlue[100],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      child: (user != null && user.photoUrl.isNotEmpty)
                          ? ClipOval(
                              child: Image.network(
                                user.photoUrl,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Text(
                                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                  style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ),
                            )
                          : Text(
                              (user != null && user.name.isNotEmpty) ? user.name[0].toUpperCase() : 'U',
                              style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'Employee',
                            style: GoogleFonts.outfit(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.designation.isNotEmpty == true ? user!.designation : 'Team Member',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[300]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32, color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DEPARTMENT', style: GoogleFonts.outfit(fontSize: 9, color: Colors.grey[400], letterSpacing: 0.8, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          user?.department.isNotEmpty == true ? user!.department : 'Operations',
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('EMPLOYEE ID', style: GoogleFonts.outfit(fontSize: 9, color: Colors.grey[400], letterSpacing: 0.8, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          user?.id.isNotEmpty == true ? user!.id : 'P57-EMP',
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const Icon(Icons.qr_code_2_rounded, color: Colors.white70, size: 28),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Admin Portal Shortcut (if admin)
          if (user?.isAdmin == true || user?.email.toLowerCase() == 'mayurailead@gmail.com') ...[
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF312E81), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white),
                title: Text(
                  'Open Administrator Dashboard',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text('Manage users, leaves, attendance & broadcasts', style: GoogleFonts.plusJakartaSans(color: Colors.grey[200], fontSize: 11)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                onTap: () => context.push('/admin'),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 3. Leave Quota Balances
          Text('Leave Quota Balances', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildQuotaRow(
                    'Annual / Paid Leave',
                    user?.getRemainingLeave('Annual / Paid Leave') ?? 0,
                    user?.getTotalLeave('Annual / Paid Leave') ?? 0,
                    user?.getUsedLeave('Annual / Paid Leave') ?? 0,
                    Colors.blue,
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildQuotaRow(
                    'Casual Leave',
                    user?.getRemainingLeave('Casual Leave') ?? 0,
                    user?.getTotalLeave('Casual Leave') ?? 0,
                    user?.getUsedLeave('Casual Leave') ?? 0,
                    Colors.orange,
                  ),
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildQuotaRow(
                    'Sick Leave',
                    user?.getRemainingLeave('Sick Leave') ?? 0,
                    user?.getTotalLeave('Sick Leave') ?? 0,
                    user?.getUsedLeave('Sick Leave') ?? 0,
                    Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 4. Employment Details
          Text('Organization & Reporting', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.supervisor_account_rounded, color: AppColors.primary),
                  title: const Text('Reporting Manager', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  subtitle: Text(
                    user?.reportingManagerName.isNotEmpty == true ? user!.reportingManagerName : 'Management',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  leading: const Icon(Icons.mail_outline_rounded, color: AppColors.primary),
                  title: const Text('Manager Email', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  subtitle: Text(
                    user?.reportingManagerEmail.isNotEmpty == true ? user!.reportingManagerEmail : 'mayurailead@gmail.com',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Settings & Security
          Text('Security & Preferences', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                  title: Text('Change / Reset Password', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Send password reset link to your email', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () async {
                    if (user == null || user.email.isEmpty) return;
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('Reset Password?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                        content: Text(
                          'A password reset link will be sent to ${user.email}. Open the link to create a new password.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.outfit())),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text('Send Link', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Password reset email sent to ${user.email}!'),
                              backgroundColor: AppColors.statusApproved,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                  title: Text('Dark Theme', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Enable low-light mode', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  value: themeMode == ThemeMode.dark || (themeMode == ThemeMode.system && isDark),
                  onChanged: (val) {
                    ref.read(themeModeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // 6. Sign Out Button
          CustomButton(
            text: 'Sign Out',
            isOutlined: true,
            backgroundColor: AppColors.statusRejected,
            textColor: AppColors.statusRejected,
            icon: Icons.logout_rounded,
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuotaRow(String title, int remaining, int total, int used, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Text(
          '$remaining / $total Days',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          '($used used)',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[500]),
        ),
      ],
    );
  }
}
