import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/request_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/announcement_provider.dart';
import '../../../providers/holiday_provider.dart';
import '../../announcements/domain/announcement_model.dart';
import '../../authentication/domain/employee_model.dart';
import '../domain/payslip_model.dart';
import '../../../core/utils/payslip_pdf_generator.dart';
import 'controllers/dashboard_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class NeoGreetingInfo {
  final String greetingText;
  final String emoji;
  final String subtitle;
  final Color themeColor;
  final Color pillColor;
  final IconData icon;

  const NeoGreetingInfo({
    required this.greetingText,
    required this.emoji,
    required this.subtitle,
    required this.themeColor,
    required this.pillColor,
    required this.icon,
  });
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  NeoGreetingInfo _getNeoGreetingInfo() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return const NeoGreetingInfo(
        greetingText: 'Good Morning',
        emoji: '🌅',
        subtitle: 'Ready to crush today\'s goals at Physique 57?',
        themeColor: AppColors.neoYellow,
        pillColor: AppColors.neoOrange,
        icon: Icons.wb_sunny_rounded,
      );
    } else if (hour >= 12 && hour < 17) {
      return const NeoGreetingInfo(
        greetingText: 'Good Afternoon',
        emoji: '☀️',
        subtitle: 'Keep up the high energy & strong momentum!',
        themeColor: AppColors.neoCyan,
        pillColor: AppColors.neoGreen,
        icon: Icons.light_mode_rounded,
      );
    } else if (hour >= 17 && hour < 22) {
      return const NeoGreetingInfo(
        greetingText: 'Good Evening',
        emoji: '🌤️',
        subtitle: 'Wrapping up a productive, high-impact day!',
        themeColor: AppColors.neoOrange,
        pillColor: AppColors.neoPink,
        icon: Icons.wb_twilight_rounded,
      );
    } else {
      return const NeoGreetingInfo(
        greetingText: 'Good Night',
        emoji: '🌙',
        subtitle: 'Time to rest, unwind, and recharge for tomorrow!',
        themeColor: AppColors.neoPurple,
        pillColor: AppColors.neoIndigo,
        icon: Icons.nights_stay_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).valueOrNull;
    final todayAttendance = ref.watch(todayAttendanceProvider);
    final streak = ref.watch(employeeAttendanceStreakProvider);
    final tasksState = ref.watch(employeeTasksProvider);
    final requestsState = ref.watch(requestsProvider);
    final unreadNotifs = ref.watch(unreadNotificationCountProvider);
    final announcementsState = ref.watch(announcementsStreamProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;
    final greetingInfo = _getNeoGreetingInfo();

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Map<String, dynamic> balancesMap = user.leaveBalances.isNotEmpty
        ? user.leaveBalances
        : EmployeeModel.defaultLeaveBalances();

    int totalLeavesAllotted = 0;
    int totalLeavesUsed = 0;
    int totalLeavesRemaining = 0;
    bool hasLowLeave = false;

    balancesMap.forEach((key, val) {
      if (val is Map) {
        final tot = (val['total'] as num?)?.toInt() ?? 0;
        final rem = (val['remaining'] as num?)?.toInt() ?? 0;
        final used = (val['used'] as num?)?.toInt() ?? (tot - rem);

        totalLeavesAllotted += tot;
        totalLeavesRemaining += rem;
        totalLeavesUsed += used;

        if (rem <= 2 && tot > 0) {
          hasLowLeave = true;
        }
      }
    });

    final formattedNetPay = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(user.netTakeHomePay.round());

    return Scaffold(
      backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
        elevation: 0,
        title: Row(
          children: [
            Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.neoYellow,
                    child: (user.photoUrl.isNotEmpty)
                        ? ClipOval(
                            child: Image.network(
                              user.photoUrl,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Text(
                                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppColors.neoBorder, fontSize: 18),
                              ),
                            ),
                          )
                        : Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppColors.neoBorder, fontSize: 18),
                          ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.neoGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: greetingInfo.pillColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(greetingInfo.icon, size: 11, color: AppColors.neoBorder),
                          const SizedBox(width: 4),
                          Text(
                            '${greetingInfo.greetingText} ${greetingInfo.emoji}',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppColors.neoBorder,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.name,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : AppColors.neoBorder,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Notification Bell with Neo-Brutalist badge
          Container(
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: AppColors.neoYellow,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: borderColor,
                  offset: const Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.neoBorder, size: 22),
                  tooltip: 'Notifications',
                  onPressed: () => context.push('/notifications'),
                ),
                if (unreadNotifs > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.neoPink,
                        shape: BoxShape.circle,
                        border: Border.all(color: borderColor, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        unreadNotifs > 9 ? '9+' : '$unreadNotifs',
                        style: GoogleFonts.outfit(color: AppColors.neoBorder, fontSize: 9, fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (user.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.neoPurple,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor,
                      offset: const Offset(2, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.neoBorder, size: 22),
                  tooltip: 'Open Admin Portal',
                  onPressed: () => context.push('/admin'),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todayAttendanceProvider);
          ref.invalidate(allAttendanceLogsProvider);
          ref.invalidate(employeeTasksProvider);
          ref.invalidate(requestsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            // 1. Ultra Eye-Catching Neo-Brutalist Greetings Hero Card
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : greetingInfo.themeColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: borderColor,
                    offset: const Offset(5, 5),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/dashboard_banner.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.black.withValues(alpha: 0.88),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.neoYellow,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.white,
                                        offset: Offset(1.5, 1.5),
                                        blurRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.workspace_premium_rounded, color: AppColors.neoBorder, size: 14),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          user.department.isNotEmpty ? user.department : 'Operations',
                                          style: GoogleFonts.outfit(color: AppColors.neoBorder, fontSize: 11.5, fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.neoCyan,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, color: AppColors.neoBorder, size: 11),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          DateFormat('EEE, MMM d').format(DateTime.now()),
                                          style: GoogleFonts.outfit(color: AppColors.neoBorder, fontSize: 11, fontWeight: FontWeight.w900),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Welcome Back, ${user.name.split(' ').first}! 👋',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            greetingInfo.subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.neoYellow,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${user.designation.isNotEmpty ? user.designation : 'Team Specialist'} • Manager: ${user.reportingManagerName.isNotEmpty ? user.reportingManagerName : 'Mayur Chaudhari'}',
                                  style: GoogleFonts.plusJakartaSans(color: Colors.grey[300], fontSize: 11.5, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.neoOrange,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.local_fire_department_rounded, color: AppColors.neoBorder, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$streak-Day Streak',
                                      style: GoogleFonts.outfit(color: AppColors.neoBorder, fontSize: 10.5, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

            // 2. Organization Broadcast Announcements Notice Board (Neo-Brutalist)
            announcementsState.when(
              data: (announcements) {
                if (announcements.isEmpty) return const SizedBox.shrink();
                final latest = announcements.first;
                Color pBg = AppColors.neoYellow;
                IconData pIcon = Icons.campaign_rounded;
                if (latest.priority == 'Urgent') {
                  pBg = AppColors.neoPink;
                  pIcon = Icons.warning_amber_rounded;
                } else if (latest.priority == 'Important') {
                  pBg = AppColors.neoOrange;
                  pIcon = Icons.error_outline_rounded;
                }

                return GestureDetector(
                  onTap: () => _showAnnouncementDialog(context, latest),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 18),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : pBg,
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: Icon(pIcon, color: AppColors.neoBorder, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      latest.title,
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white : AppColors.neoBorder),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.neoBorder,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      latest.priority,
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                latest.message,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.neoBorder,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms);
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // 3. Dynamic Shift Progress Tracker & Overtime Engine (Neo-Brutalist Card)
            todayAttendance.when(
              data: (attendance) {
                final isCheckedIn = attendance?.checkInTime != null;
                final isCheckedOut = attendance?.checkOutTime != null;
                final isLate = attendance?.status == 'Late';

                int elapsedMinutes = 0;
                if (isCheckedIn) {
                  final endTime = attendance?.checkOutTime ?? DateTime.now();
                  elapsedMinutes = endTime.difference(attendance!.checkInTime!).inMinutes;
                }
                final progress = (elapsedMinutes / 480).clamp(0.0, 1.0);
                final isOvertime = elapsedMinutes > 480;
                final overtimeMins = isOvertime ? (elapsedMinutes - 480) : 0;

                final studioName = user.department.isNotEmpty ? '${user.department} Studio' : 'Flagship Studio';

                return Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: isCheckedIn ? AppColors.neoGreen : AppColors.neoCyan,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: borderColor, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.access_time_filled_rounded,
                                      color: AppColors.neoBorder,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Daily Work Clock',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : AppColors.neoBorder),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (isCheckedIn)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLate ? AppColors.neoOrange : AppColors.neoGreen,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: borderColor, width: 1.5),
                                ),
                                child: Text(
                                  isLate ? 'Late Arrival' : 'On Time',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.neoBorder,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Geofence & Location Verification Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.neoBgDark : AppColors.neoYellow.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: AppColors.neoIndigo, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$studioName • Geofence Verified',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.neoBorder),
                                ),
                              ),
                              const Icon(Icons.verified_rounded, color: AppColors.statusApproved, size: 16),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (isCheckedOut) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.neoGreen,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: borderColor, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: borderColor,
                                  offset: const Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.neoBorder, size: 24),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Shift Completed Today', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.neoBorder)),
                                      Text('Total Logged: ${attendance?.formattedDuration ?? '8h 00m'}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.neoBorder)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (isCheckedIn) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Check In: ${DateFormat('hh:mm a').format(attendance!.checkInTime!)}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppColors.neoBorder),
                              ),
                              Text(
                                '${(progress * 100).toInt()}% of 8h Shift',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900, color: isDark ? AppColors.neoYellow : AppColors.neoIndigo),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor, width: 2),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(isOvertime ? AppColors.neoOrange : AppColors.neoYellow),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isOvertime)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.neoOrange, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor, width: 1.5)),
                              child: Text('⏱️ Overtime logged: +${overtimeMins ~/ 60}h ${overtimeMins % 60}m', style: GoogleFonts.outfit(color: AppColors.neoBorder, fontSize: 11.5, fontWeight: FontWeight.w900)),
                            ),
                          const SizedBox(height: 14),
                          CustomButton(
                            text: 'Clock Out Shift',
                            backgroundColor: AppColors.statusRejected,
                            textColor: Colors.white,
                            icon: Icons.logout_rounded,
                            onPressed: () => ref.read(todayAttendanceProvider.notifier).checkOut(),
                          ),
                        ] else ...[
                          Text(
                            'You have not checked in yet today. Clock in to automatically track shift duration.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                          ),
                          const SizedBox(height: 14),
                          CustomButton(
                            text: 'Clock In Now',
                            backgroundColor: AppColors.neoYellow,
                            textColor: AppColors.neoBorder,
                            icon: Icons.login_rounded,
                            onPressed: () => ref.read(todayAttendanceProvider.notifier).checkIn(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // 4. ⚡ Quick Action Smart Hub (Neo-Brutalist Pop Cards)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : AppColors.neoBorder),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildQuickActionBtn(context, 'Apply Leave', Icons.beach_access_rounded, AppColors.neoCyan, '/forms/leave', borderColor),
                    const SizedBox(width: 8),
                    _buildQuickActionBtn(context, 'Expense', Icons.receipt_long_rounded, AppColors.neoGreen, '/forms/expense', borderColor),
                    const SizedBox(width: 8),
                    _buildQuickActionBtn(context, 'IT Support', Icons.computer_rounded, AppColors.neoPurple, '/forms/it', borderColor),
                    const SizedBox(width: 8),
                    _buildQuickActionBtn(context, 'WFH', Icons.home_work_rounded, AppColors.neoYellow, '/forms/wfh', borderColor),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 5. 📅 Upcoming Corporate Holidays Feed (Dynamic Stream from Firestore)
            ref.watch(holidaysStreamProvider).when(
              data: (holidaysList) {
                if (holidaysList.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Upcoming Holidays & Events',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : AppColors.neoBorder),
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => context.push('/forms/leave'),
                          child: Text(
                            'Plan Leave →',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900, color: isDark ? AppColors.neoYellow : AppColors.neoIndigo),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 105,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: holidaysList.length,
                        itemBuilder: (context, index) {
                          final hol = holidaysList[index];
                          return Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: borderColor,
                                  offset: const Offset(3, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        hol.title,
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, color: isDark ? Colors.white : AppColors.neoBorder),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.neoYellow,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: borderColor, width: 1.5),
                                      ),
                                      child: Text(
                                        hol.countdownText,
                                        style: GoogleFonts.outfit(color: AppColors.neoBorder, fontSize: 10, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      DateFormat('MMM d, yyyy').format(hol.date),
                                      style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                                    ),
                                    Text(
                                      hol.type,
                                      style: GoogleFonts.outfit(fontSize: 10, color: isDark ? Colors.white70 : AppColors.neoBorder, fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // 6. Smart Leave Balance Health Cards (Neo-Brutalist)
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Leave Quota & Health',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 17, color: isDark ? Colors.white : AppColors.neoBorder),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.neoPurple,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Text(
                            '$totalLeavesRemaining Days Left ($totalLeavesUsed/$totalLeavesAllotted)',
                            style: GoogleFonts.outfit(color: AppColors.neoBorder, fontSize: 11, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    if (hasLowLeave) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.neoOrange,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderColor, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.neoBorder, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Quota Alert: Low remaining days in one or more categories.',
                                style: GoogleFonts.plusJakartaSans(color: AppColors.neoBorder, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: balancesMap.entries.map((entry) {
                        final rawName = entry.key;
                        final shortName = rawName.replaceAll(' / Paid Leave', '').replaceAll(' Leave', '');
                        final data = entry.value as Map<String, dynamic>? ?? {};
                        final tot = (data['total'] as num?)?.toInt() ?? 10;
                        final rem = (data['remaining'] as num?)?.toInt() ?? 10;

                        Color itemBg = AppColors.neoCyan;
                        if (rawName.contains('Casual')) itemBg = AppColors.neoYellow;
                        if (rawName.contains('Sick')) itemBg = AppColors.neoGreen;
                        if (rawName.contains('Maternity') || rawName.contains('Paternity')) itemBg = AppColors.neoPurple;
                        if (rawName.contains('Bereavement')) itemBg = AppColors.neoPink;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: itemBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: borderColor,
                                offset: const Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shortName,
                                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.neoBorder),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$rem/$tot Days',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.neoBorder),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            // 6.5 Group Mediclaim & Health Insurance Card (Neo-Brutalist)
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.neoPink,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: borderColor, width: 2),
                                ),
                                child: const Icon(Icons.medical_services_rounded, color: AppColors.neoBorder, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Group Mediclaim Insurance',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white : AppColors.neoBorder),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.neoGreen,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Text(
                            'Active Coverage',
                            style: GoogleFonts.outfit(color: AppColors.neoBorder, fontSize: 10.5, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.neoPink,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: borderColor,
                            offset: const Offset(3, 3),
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
                              Text(
                                'Physique 57 Health Pass',
                                style: GoogleFonts.outfit(color: AppColors.neoBorder, fontSize: 11, fontWeight: FontWeight.w900),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: borderColor, width: 1.5),
                                ),
                                child: Text(
                                  'Blood Group: ${user.bloodGroup}',
                                  style: GoogleFonts.outfit(color: AppColors.neoBorder, fontSize: 10, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              user.mediclaimId,
                              style: GoogleFonts.outfit(color: AppColors.neoBorder, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Cashless Cover', style: GoogleFonts.plusJakartaSans(color: AppColors.neoBorder, fontSize: 10, fontWeight: FontWeight.w700)),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(user.coverageAmount),
                                        style: GoogleFonts.outfit(color: AppColors.neoBorder, fontSize: 15, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('TPA Hotline', style: GoogleFonts.plusJakartaSans(color: AppColors.neoBorder, fontSize: 10, fontWeight: FontWeight.w700)),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '1800-PHY-57HEALTH',
                                        style: GoogleFonts.outfit(color: AppColors.neoBorder, fontSize: 11.5, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.phone_in_talk_rounded, size: 16, color: AppColors.statusRejected),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Emergency: ${user.emergencyContactName} (${user.emergencyContactPhone})',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : AppColors.neoBorder),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 7. Automated Compensation & Monthly Payslip Card (Neo-Brutalist)
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: AppColors.neoGreen,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: borderColor, width: 2),
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.neoBorder, size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Compensation & Earnings',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 15, color: isDark ? Colors.white : AppColors.neoBorder),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: user.payStatus == 'Processed' ? AppColors.neoGreen : AppColors.neoYellow,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Text(
                            user.payStatus,
                            style: GoogleFonts.outfit(
                              color: AppColors.neoBorder,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Net Pay Banner Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Net Take-Home Pay',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isDark ? Colors.white70 : AppColors.textSecondaryLight, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        '$formattedNetPay / mo',
                                        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? AppColors.neoYellow : AppColors.neoIndigo),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.neoYellow,
                                    foregroundColor: AppColors.neoBorder,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(color: borderColor, width: 2),
                                    ),
                                  ),
                                  icon: const Icon(Icons.receipt_long_rounded, size: 15, color: AppColors.neoBorder),
                                  onPressed: () => _showPayslipModal(context, user),
                                  label: Text('View Payslip', style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w900)),
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 20, thickness: 1.5, color: borderColor.withValues(alpha: 0.3)),
                          // Dynamic Breakdown Chips Grid
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildCompensationChip('Base Salary', '₹${user.baseSalary.round()}', AppColors.neoCyan, borderColor),
                              _buildCompensationChip('HRA (${user.hraPercentage.toInt()}%)', '+₹${user.hraAmount.round()}', AppColors.neoGreen, borderColor),
                              _buildCompensationChip('Allowances (${user.allowancePercentage.toInt()}%)', '+₹${user.allowanceAmount.round()}', AppColors.neoYellow, borderColor),
                              _buildCompensationChip('Incentive', '+₹${user.monthlyIncentive.round()}', AppColors.neoPurple, borderColor),
                              _buildCompensationChip('PF Deduct (${user.pfPercentage.toInt()}%)', '-₹${user.pfDeduction.round()}', AppColors.neoPink, borderColor),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 8. Request Center Statistics (Neo-Brutalist Pop Stat Cards)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Request Center',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : AppColors.neoBorder),
                    ),
                    InkWell(
                      onTap: () => context.push('/my-requests'),
                      child: Text(
                        'View All →',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w900, color: isDark ? AppColors.neoYellow : AppColors.neoIndigo),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard('Pending', requestsState.pendingCount.toString(), AppColors.neoYellow, borderColor),
                    const SizedBox(width: 10),
                    _buildStatCard('Approved', requestsState.approvedCount.toString(), AppColors.neoGreen, borderColor),
                    const SizedBox(width: 10),
                    _buildStatCard('Rejected', requestsState.rejectedCount.toString(), AppColors.neoPink, borderColor),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 9. Interactive Action Tasks with Filter Tabs (Neo-Brutalist)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Assigned Tasks',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : AppColors.neoBorder),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Task Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'In Progress', 'Pending', 'Completed'].map((f) {
                  final taskFilter = ref.watch(dashboardTaskFilterProvider);
                  final isSelected = taskFilter == f;
                  return GestureDetector(
                    onTap: () => ref.read(dashboardTaskFilterProvider.notifier).state = f,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.neoYellow : (isDark ? AppColors.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 2),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: borderColor,
                                  offset: const Offset(2, 2),
                                  blurRadius: 0,
                                )
                              ]
                            : null,
                      ),
                      child: Text(
                        f,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? AppColors.neoBorder : (isDark ? Colors.white : AppColors.neoBorder),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            tasksState.when(
              data: (tasks) {
                final currentTaskFilter = ref.watch(dashboardTaskFilterProvider);
                final filteredTasks = tasks.where((t) {
                  if (currentTaskFilter == 'All') return true;
                  return t.status.toLowerCase() == currentTaskFilter.toLowerCase();
                }).toList();

                if (filteredTasks.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        'No $currentTaskFilter tasks found.',
                        style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w700),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filteredTasks.map((task) {
                    final isCompleted = task.status == 'Completed';
                    final isInProgress = task.status == 'In Progress';
                    final isOverdue = task.dueDate.isBefore(DateTime.now()) && !isCompleted;

                    Color taskTagBg = AppColors.neoYellow;
                    if (isCompleted) taskTagBg = AppColors.neoGreen;
                    if (isInProgress) taskTagBg = AppColors.neoCyan;
                    if (isOverdue) taskTagBg = AppColors.neoPink;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: borderColor,
                            offset: const Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      color: isCompleted ? Colors.grey : (isDark ? Colors.white : AppColors.neoBorder),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: taskTagBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: borderColor, width: 1.5),
                                  ),
                                  child: Text(
                                    isOverdue ? 'Overdue' : task.status,
                                    style: GoogleFonts.outfit(
                                      color: AppColors.neoBorder,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              task.description,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Due: ${DateFormat('yyyy-MM-dd').format(task.dueDate)}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: isOverdue ? AppColors.statusRejected : Colors.grey[500]),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!isCompleted && !isInProgress)
                                      TextButton(
                                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                                        onPressed: () {
                                          ref.read(employeeTasksProvider.notifier).updateTaskStatus(task.id, 'In Progress');
                                        },
                                        child: Text('Start Task', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, color: isDark ? AppColors.neoYellow : AppColors.neoIndigo)),
                                      ),
                                    if (!isCompleted) ...[
                                      const SizedBox(width: 4),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.neoGreen,
                                          foregroundColor: AppColors.neoBorder,
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: BorderSide(color: borderColor, width: 1.5),
                                          ),
                                          elevation: 0,
                                        ),
                                        onPressed: () {
                                          ref.read(employeeTasksProvider.notifier).updateTaskStatus(task.id, 'Completed');
                                        },
                                        child: Text('Mark Done', style: GoogleFonts.outfit(color: AppColors.neoBorder, fontSize: 12, fontWeight: FontWeight.w900)),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(BuildContext context, String label, IconData icon, Color color, String route, Color borderColor) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: borderColor,
                offset: const Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Icon(icon, color: AppColors.neoBorder, size: 18),
              ),
              const SizedBox(height: 5),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.neoBorder),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompensationChip(String label, String amount, Color color, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: borderColor,
            offset: const Offset(1.5, 1.5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.neoBorder),
          ),
          Text(
            amount,
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.neoBorder),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color, Color borderColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: borderColor,
              offset: const Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.neoBorder),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.neoBorder),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext context, AnnouncementModel ann) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor, width: 2.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.campaign_rounded, color: AppColors.neoBorder, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text(ann.title, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.neoYellow,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Text('Priority: ${ann.priority}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppColors.neoBorder, fontSize: 11)),
            ),
            const SizedBox(height: 10),
            Text(ann.message, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('Published: ${DateFormat('yyyy-MM-dd hh:mm a').format(ann.createdAt)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neoYellow),
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppColors.neoBorder)),
          ),
        ],
      ),
    );
  }

  void _showPayslipModal(BuildContext context, dynamic user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;

    final empModel = (user is EmployeeModel)
        ? user
        : const EmployeeModel(
            id: 'EMP-001',
            name: 'Mayur Chaudhari',
            email: 'mayurchaudhari@gmail.com',
            department: 'Operations',
            designation: 'Studio Operations Lead',
            reportingManagerName: 'Mayur Chaudhari',
            reportingManagerEmail: 'mayurchaudhari@gmail.com',
            photoUrl: '',
          );

    final payslips = PayslipModel.generateLast6Months(empModel);
    int selectedIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: borderColor, width: 3),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final selectedPayslip = payslips[selectedIndex];

          final baseStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(selectedPayslip.baseSalary);
          final hraStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(selectedPayslip.hraAmount);
          final allowStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(selectedPayslip.allowanceAmount);
          final incentiveStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(selectedPayslip.monthlyIncentive);
          final otStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(selectedPayslip.overtimePay);
          final grossStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(selectedPayslip.grossSalary);
          final pfStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(selectedPayslip.pfDeduction);
          final taxStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(selectedPayslip.taxDeduction);
          final netStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(selectedPayslip.netTakeHomePay);

          return Container(
            padding: const EdgeInsets.all(22),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.neoYellow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor, width: 2),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.neoBorder, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '6-Month Payslip Downloader',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 17, color: isDark ? Colors.white : AppColors.neoBorder),
                            ),
                          ),
                          Text(
                            '${selectedPayslip.employeeName} • ${selectedPayslip.department}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Horizontal Month Selector Tabs (Last 6 Months)
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: payslips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final p = payslips[index];
                      final isSelected = index == selectedIndex;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            selectedIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.neoYellow : (isDark ? AppColors.surfaceDark : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.5),
                            boxShadow: isSelected
                                ? [BoxShadow(color: borderColor, offset: const Offset(2, 2), blurRadius: 0)]
                                : null,
                          ),
                          child: Text(
                            p.monthYearStr,
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? AppColors.neoBorder : (isDark ? Colors.white70 : AppColors.neoBorder),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: ListView(
                    children: [
                      // Payslip Status Banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.neoBgLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Salary Month: ${selectedPayslip.monthYearStr}', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, color: isDark ? Colors.white : AppColors.neoBorder)),
                                Text('Transaction: ${selectedPayslip.transactionId}', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.grey)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.neoGreen,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: borderColor, width: 1.5),
                              ),
                              child: Text('PAID', style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.neoBorder)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildPayslipRow('Basic Salary', baseStr, isDark, borderColor),
                      _buildPayslipRow('HRA', hraStr, isDark, borderColor),
                      _buildPayslipRow('Allowances', allowStr, isDark, borderColor),
                      _buildPayslipRow('Incentives', incentiveStr, isDark, borderColor, color: isDark ? AppColors.neoYellow : AppColors.neoIndigo),
                      if (selectedPayslip.overtimePay > 0)
                        _buildPayslipRow('Overtime Pay', otStr, isDark, borderColor, color: AppColors.neoGreen),
                      Divider(height: 16, thickness: 2, color: borderColor),
                      _buildPayslipRow('Gross Pay', grossStr, isDark, borderColor, isBold: true),
                      _buildPayslipRow('PF Deduction', '- $pfStr', isDark, borderColor, color: AppColors.statusRejected),
                      if (selectedPayslip.taxDeduction > 0)
                        _buildPayslipRow('TDS / Tax', '- $taxStr', isDark, borderColor, color: AppColors.statusRejected),
                      Divider(height: 16, thickness: 2, color: borderColor),
                      _buildPayslipRow('Net Pay', netStr, isDark, borderColor, isBold: true, color: isDark ? AppColors.neoGreen : AppColors.statusApproved),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Download PDF Button & Share Button
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neoYellow,
                          foregroundColor: AppColors.neoBorder,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: borderColor, width: 2.5),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.picture_as_pdf_rounded, size: 20, color: AppColors.neoBorder),
                        onPressed: () {
                          PayslipPdfGenerator.downloadAndPrintPdf(selectedPayslip);
                        },
                        label: Text('DOWNLOAD PAYSLIP (PDF)', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neoCyan,
                          foregroundColor: AppColors.neoBorder,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: borderColor, width: 2.5),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.share_rounded, size: 18, color: AppColors.neoBorder),
                        onPressed: () {
                          PayslipPdfGenerator.sharePdf(selectedPayslip);
                        },
                        label: Text('SHARE', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPayslipRow(String label, String value, bool isDark, Color borderColor, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                color: isDark ? Colors.white : AppColors.neoBorder,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 14.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: color ?? (isDark ? Colors.white : AppColors.neoBorder),
            ),
          ),
        ],
      ),
    );
  }
}
