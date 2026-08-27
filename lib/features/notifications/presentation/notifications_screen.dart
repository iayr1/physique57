import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotifications = ref.watch(notificationProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              ref.read(notificationProvider.notifier).markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read.'), duration: Duration(seconds: 2)),
              );
            },
            icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.primary),
            label: Text(
              'Mark All Read',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: asyncNotifications.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 14),
                  Text(
                    'No notifications right now',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You\'re all caught up with company alerts and requests.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final notif = list[index];
              final isAnn = notif.title.contains('📢') || notif.requestId.startsWith('ANN-');
              final isTask = notif.title.contains('📋') || notif.title.contains('Task') || notif.requestId.startsWith('TSK-');

              Color iconColor = AppColors.primary;
              IconData notifIcon = Icons.notifications_rounded;
              if (isAnn) {
                iconColor = Colors.orange;
                notifIcon = Icons.campaign_rounded;
              } else if (isTask) {
                iconColor = Colors.teal;
                notifIcon = Icons.task_alt_rounded;
              } else if (notif.title.contains('Approved')) {
                iconColor = Colors.green;
                notifIcon = Icons.check_circle_outline_rounded;
              } else if (notif.title.contains('Rejected')) {
                iconColor = Colors.red;
                notifIcon = Icons.cancel_outlined;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                elevation: 0,
                color: notif.isRead
                    ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: notif.isRead ? const Color(0xFFE2E8F0) : AppColors.primary.withValues(alpha: 0.4),
                    width: notif.isRead ? 1 : 1.5,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(notifIcon, color: iconColor, size: 20),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                        notif.message,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormatter.formatDateTime(notif.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textSecondaryDark : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    ref.read(notificationProvider.notifier).markAsRead(notif.id);
                    if (notif.requestId.isNotEmpty && !isAnn && !isTask) {
                      context.push('/requests/${notif.requestId}');
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
