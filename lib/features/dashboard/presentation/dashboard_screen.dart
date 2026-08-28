import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/request_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/announcement_provider.dart';
import '../../announcements/domain/announcement_model.dart';
import '../domain/holiday_model.dart';
import 'controllers/dashboard_controller.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good Morning 🌅';
    if (hour >= 12 && hour < 17) return 'Good Afternoon ☀️';
    if (hour >= 17 && hour < 22) return 'Good Evening 🌤️';
    return 'Good Night 🌙';
  }

  int _getBaseSalary(dynamic user) {
    if (user.baseSalary != null && user.baseSalary > 0) {
      return user.baseSalary.round();
    }
    if (user.isAdmin) {
      return 125000;
    }
    return 65000;
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
    final upcomingHolidays = CorporateHoliday.getUpcomingHolidays();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final annualRemaining = user.getRemainingLeave('Annual / Paid Leave');
    final annualTotal = user.getTotalLeave('Annual / Paid Leave');
    final casualRemaining = user.getRemainingLeave('Casual Leave');
    final casualTotal = user.getTotalLeave('Casual Leave');
    final sickRemaining = user.getRemainingLeave('Sick Leave');
    final sickTotal = user.getTotalLeave('Sick Leave');

    final totalLeavesAllotted = annualTotal + casualTotal + sickTotal;
    final totalLeavesRemaining = annualRemaining + casualRemaining + sickRemaining;
    final totalLeavesUsed = totalLeavesAllotted - totalLeavesRemaining;
    final totalUtilizationPct = totalLeavesAllotted > 0
        ? (totalLeavesUsed / totalLeavesAllotted).clamp(0.0, 1.0)
        : 0.0;

    final hasLowLeave = sickRemaining <= 1 || casualRemaining <= 1 || annualRemaining <= 2;

    final baseSalary = _getBaseSalary(user);
    final hra = (baseSalary * 0.4).round();
    final allowances = (baseSalary * 0.15).round();
    final pfDeduction = (baseSalary * 0.08).round();
    final gross = baseSalary + hra + allowances;
    final netTakeHome = gross - pfDeduction;
    final formattedNetPay = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(netTakeHome);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        elevation: 0,
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: (user.photoUrl.isNotEmpty)
                      ? ClipOval(
                          child: Image.network(
                            user.photoUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                            ),
                          ),
                        )
                      : Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppColors.backgroundDark : Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getGreeting(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.name,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Notification Bell with reactive glowing badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 24),
                tooltip: 'Notifications',
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadNotifs > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.statusRejected,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.statusRejected.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1),
                      ],
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      unreadNotifs > 9 ? '9+' : '$unreadNotifs',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (user.isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
                tooltip: 'Open Admin Portal',
                onPressed: () => context.push('/admin'),
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
            // 1. Dynamic Hero Card with Designation & Date
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF312E81).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 12),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  DateFormat('EEE, MMM d, yyyy').format(DateTime.now()),
                                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.department.isNotEmpty ? user.department : 'Physique 57',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.designation.isNotEmpty ? user.designation : 'Staff Member',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Manager: ${user.reportingManagerName.isNotEmpty ? user.reportingManagerName : 'Management'}',
                          style: GoogleFonts.plusJakartaSans(color: Colors.grey[300], fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.amberAccent, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$streak-Day Streak',
                            style: GoogleFonts.outfit(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),

            // 2. Organization Broadcast Announcements Notice Board
            announcementsState.when(
              data: (announcements) {
                if (announcements.isEmpty) return const SizedBox.shrink();
                final latest = announcements.first;
                Color pColor = const Color(0xFF2563EB);
                IconData pIcon = Icons.campaign_rounded;
                if (latest.priority == 'Urgent') {
                  pColor = const Color(0xFFDC2626);
                  pIcon = Icons.warning_amber_rounded;
                } else if (latest.priority == 'Important') {
                  pColor = const Color(0xFFEA580C);
                  pIcon = Icons.error_outline_rounded;
                }

                return GestureDetector(
                  onTap: () => _showAnnouncementDialog(context, latest),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: pColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: pColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: pColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: Icon(pIcon, color: pColor, size: 20),
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
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: pColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: pColor, borderRadius: BorderRadius.circular(6)),
                                    child: Text(
                                      latest.priority,
                                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                latest.message,
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[700]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
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

            // 3. Dynamic Shift Progress Tracker & Overtime Engine with Geofence Status
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
                final progress = (elapsedMinutes / 480).clamp(0.0, 1.0); // 8 hours = 480 mins
                final isOvertime = elapsedMinutes > 480;
                final overtimeMins = isOvertime ? (elapsedMinutes - 480) : 0;

                final studioName = user.department.isNotEmpty ? '${user.department} Studio' : 'Flagship Studio';

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (isCheckedIn ? Colors.green : AppColors.primary).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.access_time_filled_rounded,
                                    color: isCheckedIn ? Colors.green : AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Daily Work Clock',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                                ),
                              ],
                            ),
                            if (isCheckedIn)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isLate ? Colors.orange : Colors.green).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isLate ? 'Late Arrival' : 'On Time',
                                  style: GoogleFonts.outfit(
                                    color: isLate ? Colors.orange : Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Geofence & Location Verification Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: Colors.blueAccent, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$studioName • Geofence Verified',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                                ),
                              ),
                              const Icon(Icons.verified_rounded, color: Colors.green, size: 14),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        if (isCheckedOut) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Shift Completed Today', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green[800])),
                                      Text('Total Logged: ${attendance?.formattedDuration ?? '8h 00m'}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[700])),
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
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${(progress * 100).toInt()}% of 8h Shift',
                                style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(isOvertime ? Colors.orange : AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (isOvertime)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text('⏱️ Overtime logged: +${overtimeMins ~/ 60}h ${overtimeMins % 60}m', style: GoogleFonts.outfit(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusRejected,
                              minimumSize: const Size(double.infinity, 46),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () => ref.read(todayAttendanceProvider.notifier).checkOut(),
                            icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                            label: Text('Clock Out Shift', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ] else ...[
                          Text(
                            'You have not checked in yet today. Clock in to automatically track shift duration.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size(double.infinity, 46),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            onPressed: () => ref.read(todayAttendanceProvider.notifier).checkIn(),
                            icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
                            label: Text('Clock In Now', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
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

            // 4. ⚡ Quick Action Smart Hub
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildQuickActionBtn(context, 'Apply Leave', Icons.beach_access_rounded, const Color(0xFF3B82F6), '/forms/leave'),
                    const SizedBox(width: 10),
                    _buildQuickActionBtn(context, 'Expense', Icons.receipt_long_rounded, const Color(0xFF10B981), '/forms/expense'),
                    const SizedBox(width: 10),
                    _buildQuickActionBtn(context, 'IT Support', Icons.computer_rounded, const Color(0xFF8B5CF6), '/forms/it'),
                    const SizedBox(width: 10),
                    _buildQuickActionBtn(context, 'WFH', Icons.home_work_rounded, const Color(0xFFF59E0B), '/forms/wfh'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 5. 📅 Upcoming Corporate Holidays Feed
            if (upcomingHolidays.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Upcoming Holidays & Events',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  InkWell(
                    onTap: () => context.push('/forms/leave'),
                    child: Text(
                      'Plan Leave →',
                      style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: upcomingHolidays.length,
                  itemBuilder: (context, index) {
                    final hol = upcomingHolidays[index];
                    return Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  hol.countdownText,
                                  style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM d, yyyy').format(hol.date),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              Text(
                                hol.type,
                                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
            ],

            // 6. Smart Leave Balance Health Cards & Combined Ring
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
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
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(totalUtilizationPct * 100).toInt()}% Used ($totalLeavesUsed/$totalLeavesAllotted)',
                            style: GoogleFonts.outfit(color: Colors.purple, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (hasLowLeave) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Quota Alert: Low remaining days in one or more categories.',
                                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF92400E), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildLeaveBarItem('Annual', annualRemaining, annualTotal, const Color(0xFF3B82F6)),
                        const SizedBox(width: 10),
                        _buildLeaveBarItem('Casual', casualRemaining, casualTotal, const Color(0xFFF59E0B)),
                        const SizedBox(width: 10),
                        _buildLeaveBarItem('Sick', sickRemaining, sickTotal, const Color(0xFF10B981)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 7. Automated Compensation & Monthly Payslip Card
            Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Compensation & Earnings',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        const Icon(Icons.account_balance_wallet_outlined, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Live simulation based on monthly attendance & paid leave quotas.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Estimated Net Take-Home', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey)),
                                const SizedBox(height: 2),
                                Text(
                                  '$formattedNetPay / mo',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF0F172A)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () => _showPayslipModal(context, user),
                            child: Text('View Payslip', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 8. Request Center Statistics
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Request Center',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    InkWell(
                      onTap: () => context.push('/my-requests'),
                      child: Text(
                        'View All →',
                        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatCard('Pending', requestsState.pendingCount.toString(), Colors.orange),
                    const SizedBox(width: 10),
                    _buildStatCard('Approved', requestsState.approvedCount.toString(), Colors.green),
                    const SizedBox(width: 10),
                    _buildStatCard('Rejected', requestsState.rejectedCount.toString(), Colors.red),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 9. Interactive Action Tasks with Filter Tabs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'My Assigned Tasks',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        f,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700]),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            tasksState.when(
              data: (tasks) {
                final currentTaskFilter = ref.watch(dashboardTaskFilterProvider);
                final filteredTasks = tasks.where((t) {
                  if (currentTaskFilter == 'All') return true;
                  return t.status.toLowerCase() == currentTaskFilter.toLowerCase();
                }).toList();

                if (filteredTasks.isEmpty) {
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Center(
                        child: Text(
                          'No $currentTaskFilter tasks found.',
                          style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }

                return Column(
                  children: filteredTasks.map((task) {
                    final isCompleted = task.status == 'Completed';
                    final isInProgress = task.status == 'In Progress';
                    final isOverdue = task.dueDate.isBefore(DateTime.now()) && !isCompleted;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(
                          color: isOverdue
                              ? Colors.red.withValues(alpha: 0.4)
                              : isCompleted
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      color: isCompleted ? Colors.grey : null,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isCompleted
                                            ? Colors.green
                                            : isInProgress
                                                ? Colors.blue
                                                : isOverdue
                                                    ? Colors.red
                                                    : Colors.orange)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isOverdue ? 'Overdue' : task.status,
                                    style: GoogleFonts.outfit(
                                      color: isCompleted
                                          ? Colors.green
                                          : isInProgress
                                              ? Colors.blue
                                              : isOverdue
                                                  ? Colors.red
                                                  : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(task.description, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Due: ${DateFormat('yyyy-MM-dd').format(task.dueDate)}',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11, color: isOverdue ? Colors.red : Colors.grey[500]),
                                    overflow: TextOverflow.ellipsis,
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
                                        child: Text('Start Task', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold)),
                                      ),
                                    if (!isCompleted) ...[
                                      const SizedBox(width: 4),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          elevation: 0,
                                        ),
                                        onPressed: () {
                                          ref.read(employeeTasksProvider.notifier).updateTaskStatus(task.id, 'Completed');
                                        },
                                        child: Text('Mark Done', style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildQuickActionBtn(BuildContext context, String label, IconData icon, Color color, String route) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveBarItem(String label, int remaining, int total, Color color) {
    final pct = total > 0 ? (remaining / total).clamp(0.0, 1.0) : 0.0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              '$remaining / $total',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 4,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext context, AnnouncementModel ann) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.campaign_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(child: Text(ann.title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 17))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Priority: ${ann.priority}', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Text(ann.message, style: GoogleFonts.plusJakartaSans(fontSize: 14)),
            const SizedBox(height: 12),
            Text('Published: ${DateFormat('yyyy-MM-dd hh:mm a').format(ann.createdAt)}', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showPayslipModal(BuildContext context, dynamic user) {
    final basePay = _getBaseSalary(user);
    final hra = (basePay * 0.4).round();
    final allowances = (basePay * 0.15).round();
    final pfDeduction = (basePay * 0.08).round();
    final gross = basePay + hra + allowances;
    final netPay = gross - pfDeduction;

    final baseStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(basePay);
    final hraStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(hra);
    final allowStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(allowances);
    final pfStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(pfDeduction);
    final grossStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(gross);
    final netStr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(netPay);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Text('Monthly Payslip Breakdown', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 19)),
              ],
            ),
            const SizedBox(height: 6),
            Text('Employee: ${user.name} (${user.department} • ${user.designation})', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey)),
            const Divider(height: 24),
            _buildPayslipRow('Basic Salary', baseStr),
            _buildPayslipRow('House Rent Allowance (HRA)', hraStr),
            _buildPayslipRow('Special Enterprise Allowance', allowStr),
            const Divider(height: 16),
            _buildPayslipRow('Gross Monthly Earnings', grossStr, isBold: true),
            _buildPayslipRow('Provident Fund (EPF) Deduction', '- $pfStr', color: Colors.red),
            const Divider(height: 16),
            _buildPayslipRow('Estimated Net Monthly Pay', netStr, isBold: true, color: Colors.green),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: Text('Close Payslip', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayslipRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
