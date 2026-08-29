import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'All'; // 'All', 'Unread', 'Requests', 'Tasks'

  @override
  Widget build(BuildContext context) {
    final asyncNotifications = ref.watch(notificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : AppColors.neoBorder,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'All notifications marked as read.',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: AppColors.neoBorder,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.neoYellow,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.done_all_rounded, size: 14, color: AppColors.neoBorder),
                    const SizedBox(width: 4),
                    Text(
                      'Mark Read',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 11.5,
                        color: AppColors.neoBorder,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: asyncNotifications.when(
        data: (list) {
          final unreadCount = list.where((n) => !n.isRead).length;

          // Filter list
          final filteredList = list.where((n) {
            if (_selectedFilter == 'Unread') return !n.isRead;
            if (_selectedFilter == 'Requests') {
              return n.title.contains('Request') || n.title.contains('Approved') || n.title.contains('Rejected');
            }
            if (_selectedFilter == 'Tasks') {
              return n.title.contains('Task') || n.requestId.startsWith('TSK-');
            }
            return true;
          }).toList();

          return Column(
            children: [
              // 1. Filter Chips Row
              Container(
                height: 44,
                margin: const EdgeInsets.only(top: 4, bottom: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('All', list.length, isDark, borderColor),
                    _buildFilterChip('Unread', unreadCount, isDark, borderColor),
                    _buildFilterChip('Requests', null, isDark, borderColor),
                    _buildFilterChip('Tasks', null, isDark, borderColor),
                  ],
                ),
              ),

              // 2. Main Content
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.neoYellow,
                                shape: BoxShape.circle,
                                border: Border.all(color: borderColor, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: borderColor,
                                    offset: const Offset(4, 4),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                size: 48,
                                color: isDark ? Colors.white : AppColors.neoBorder,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _selectedFilter == 'Unread' ? 'No unread notifications' : 'No notifications right now',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : AppColors.neoBorder,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'You\'re all caught up with company alerts & updates.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final notif = filteredList[index];
                          final isAnn = notif.title.contains('📢') || notif.requestId.startsWith('ANN-');
                          final isTask = notif.title.contains('📋') || notif.title.contains('Task') || notif.requestId.startsWith('TSK-');

                          Color iconBg = AppColors.neoCyan;
                          IconData notifIcon = Icons.notifications_rounded;
                          if (isAnn) {
                            iconBg = AppColors.neoYellow;
                            notifIcon = Icons.campaign_rounded;
                          } else if (isTask) {
                            iconBg = AppColors.neoPurple;
                            notifIcon = Icons.task_alt_rounded;
                          } else if (notif.title.contains('Approved')) {
                            iconBg = AppColors.neoGreen;
                            notifIcon = Icons.check_circle_rounded;
                          } else if (notif.title.contains('Rejected')) {
                            iconBg = AppColors.neoPink;
                            notifIcon = Icons.cancel_rounded;
                          }

                          // Card background color:
                          // Light mode: Always crisp clean WHITE (or light yellow tint if unread)
                          // Dark mode: Deep Slate #1E293B
                          final cardBg = isDark
                              ? AppColors.surfaceDark
                              : (notif.isRead ? Colors.white : const Color(0xFFFFFDF0));

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: cardBg,
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
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(15),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () {
                                  ref.read(notificationProvider.notifier).markAsRead(notif.id);
                                  if (notif.requestId.isNotEmpty && !isAnn && !isTask) {
                                    context.push('/requests/${notif.requestId}');
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Category Icon Badge
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: iconBg,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: borderColor, width: 2),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: AppColors.neoBorder,
                                              offset: Offset(1.5, 1.5),
                                              blurRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Icon(notifIcon, color: AppColors.neoBorder, size: 20),
                                      ),
                                      const SizedBox(width: 14),

                                      // Text Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    notif.title,
                                                    style: GoogleFonts.outfit(
                                                      fontWeight: FontWeight.w900,
                                                      fontSize: 15.5,
                                                      letterSpacing: -0.2,
                                                      color: isDark ? Colors.white : AppColors.neoBorder,
                                                    ),
                                                  ),
                                                ),
                                                if (!notif.isRead) ...[
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.neoPink,
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: borderColor, width: 1.5),
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: AppColors.neoBorder,
                                                          offset: Offset(1, 1),
                                                          blurRadius: 0,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Text(
                                                      'NEW',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w900,
                                                        color: AppColors.neoBorder,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              notif.message,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                height: 1.35,
                                                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF334155),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.schedule_rounded,
                                                  size: 13,
                                                  color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  DateFormatter.formatDateTime(notif.timestamp),
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.w700,
                                                    color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
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
                              ),
                            ),
                          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04, end: 0);
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildFilterChip(String label, int? count, bool isDark, Color borderColor) {
    final isSelected = _selectedFilter == label;
    final chipBg = isSelected
        ? AppColors.neoYellow
        : (isDark ? AppColors.surfaceDark : Colors.white);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = label),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: chipBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: borderColor,
                  offset: const Offset(2, 2),
                  blurRadius: 0,
                ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5,
                  color: isDark && !isSelected ? Colors.white : AppColors.neoBorder,
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.neoPink : AppColors.neoYellow,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor, width: 1),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.neoBorder,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
