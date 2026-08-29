import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
        elevation: 0,
        title: Text(
          'My Profile & Settings',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22, color: isDark ? Colors.white : AppColors.neoBorder),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // 1. Digital Employee ID Card (Neo-Brutalist High Impact)
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.neoYellow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: borderColor,
                  offset: const Offset(5, 5),
                  blurRadius: 0,
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
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.neoYellow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              'assets/images/app_logo.png',
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PHYSIQUE 57',
                          style: GoogleFonts.outfit(
                            color: isDark ? Colors.white : AppColors.neoBorder,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: user?.isAdmin == true ? AppColors.neoPurple : AppColors.neoCyan,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: borderColor,
                            offset: const Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        user?.isAdmin == true ? 'ADMINISTRATOR' : 'STAFF MEMBER',
                        style: GoogleFonts.outfit(
                          color: AppColors.neoBorder,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: borderColor,
                            offset: const Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: AppColors.neoPink,
                        child: (user != null && user.photoUrl.isNotEmpty)
                            ? ClipOval(
                                child: Image.network(
                                  user.photoUrl,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                    style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.neoBorder),
                                  ),
                                ),
                              )
                            : Text(
                                (user != null && user.name.isNotEmpty) ? user.name[0].toUpperCase() : 'U',
                                style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.neoBorder),
                              ),
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
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.neoBorder,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.designation.isNotEmpty == true ? user!.designation : 'Team Member',
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? AppColors.textSecondaryDark : AppColors.neoBorder),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: 32, thickness: 2, color: borderColor),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DEPARTMENT', style: GoogleFonts.outfit(fontSize: 10, color: isDark ? AppColors.textSecondaryDark : AppColors.neoBorder, letterSpacing: 0.8, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(
                            user?.department.isNotEmpty == true ? user!.department : 'Operations',
                            style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white : AppColors.neoBorder, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('EMPLOYEE ID', style: GoogleFonts.outfit(fontSize: 10, color: isDark ? AppColors.textSecondaryDark : AppColors.neoBorder, letterSpacing: 0.8, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(
                            user?.id.isNotEmpty == true ? user!.id : 'P57-EMP',
                            style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white : AppColors.neoBorder, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.qr_code_2_rounded, color: isDark ? Colors.white : AppColors.neoBorder, size: 30),
                  ],
                ),
                Divider(height: 20, thickness: 2, color: borderColor),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppColors.neoCyan,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      child: const Icon(Icons.supervisor_account_rounded, size: 14, color: AppColors.neoBorder),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('REPORTING MANAGER', style: GoogleFonts.outfit(fontSize: 9.5, color: isDark ? AppColors.textSecondaryDark : AppColors.neoBorder, letterSpacing: 0.8, fontWeight: FontWeight.w900)),
                          Text(
                            user?.reportingManagerName.isNotEmpty == true ? user!.reportingManagerName : 'Mayur Chaudhari',
                            style: GoogleFonts.outfit(fontSize: 13, color: isDark ? Colors.white : AppColors.neoBorder, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // 2. Admin Portal Shortcut (if admin)
          if (user?.isAdmin == true) ...[
            Container(
              decoration: BoxDecoration(
                color: AppColors.neoPurple,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: borderColor,
                    offset: const Offset(4, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.neoBorder, size: 28),
                title: Text(
                  'Open Administrator Dashboard',
                  style: GoogleFonts.outfit(color: AppColors.neoBorder, fontWeight: FontWeight.w900, fontSize: 16),
                ),
                subtitle: Text('Manage users, leaves, attendance & broadcasts', style: GoogleFonts.plusJakartaSans(color: AppColors.neoBorder, fontWeight: FontWeight.w600, fontSize: 11.5)),
                trailing: const Icon(Icons.arrow_forward_rounded, color: AppColors.neoBorder, size: 20),
                onTap: () => context.push('/admin'),
              ),
            ),
            const SizedBox(height: 22),
          ],

          // 3. Leave Quota Balances
          Text('Leave Quota Balances', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.neoBorder)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: borderColor,
                  offset: const Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildQuotaRow(
                    'Annual / Paid Leave',
                    user?.getRemainingLeave('Annual / Paid Leave') ?? 0,
                    user?.getTotalLeave('Annual / Paid Leave') ?? 0,
                    user?.getUsedLeave('Annual / Paid Leave') ?? 0,
                    AppColors.neoCyan,
                    borderColor,
                  ),
                  Divider(height: 18, thickness: 1.5, color: borderColor.withValues(alpha: 0.3)),
                  _buildQuotaRow(
                    'Casual Leave',
                    user?.getRemainingLeave('Casual Leave') ?? 0,
                    user?.getTotalLeave('Casual Leave') ?? 0,
                    user?.getUsedLeave('Casual Leave') ?? 0,
                    AppColors.neoYellow,
                    borderColor,
                  ),
                  Divider(height: 18, thickness: 1.5, color: borderColor.withValues(alpha: 0.3)),
                  _buildQuotaRow(
                    'Sick Leave',
                    user?.getRemainingLeave('Sick Leave') ?? 0,
                    user?.getTotalLeave('Sick Leave') ?? 0,
                    user?.getUsedLeave('Sick Leave') ?? 0,
                    AppColors.neoGreen,
                    borderColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // 4. Employment Details
          Text('Organization & Reporting', style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w900, color: isDark ? Colors.white : AppColors.neoBorder)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: borderColor,
                  offset: const Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.neoCyan, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor, width: 1.5)),
                    child: const Icon(Icons.supervisor_account_rounded, color: AppColors.neoBorder, size: 20),
                  ),
                  title: Text('Reporting Manager', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[600])),
                  subtitle: Text(
                    user?.reportingManagerName.isNotEmpty == true ? user!.reportingManagerName : 'Management',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white : AppColors.neoBorder),
                  ),
                ),
                Divider(height: 1, thickness: 1.5, color: borderColor.withValues(alpha: 0.3)),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.neoYellow, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor, width: 1.5)),
                    child: const Icon(Icons.mail_outline_rounded, color: AppColors.neoBorder, size: 20),
                  ),
                  title: Text('Manager Email', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[600])),
                  subtitle: Text(
                    user?.reportingManagerEmail.isNotEmpty == true ? user!.reportingManagerEmail : 'admin@physique57.com',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? Colors.white : AppColors.neoBorder),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          const SizedBox(height: 28),

          // 5. High-Contrast Log Out Button
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.statusRejected,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: borderColor,
                  offset: const Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 22),
              label: Text(
                'Log Out',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: () async {
                await ref.read(authProvider.notifier).signOut();
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuotaRow(String title, int remaining, int total, int used, Color color, Color borderColor) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 14),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Text(
            '$remaining / $total Days',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, color: AppColors.neoBorder),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '($used used)',
          style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[600]),
        ),
      ],
    );
  }
}
