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
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;

    return Scaffold(
      backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? AppColors.neoBgDark : AppColors.neoBgLight,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 22, color: isDark ? Colors.white : AppColors.neoBorder),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.neoYellow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 2),
            ),
            child: TextButton.icon(
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read.'), duration: Duration(seconds: 2)),
                );
              },
              icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.neoBorder),
              label: Text(
                'Mark All Read',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  color: AppColors.neoBorder,
                ),
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
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.neoBorder,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You\'re all caught up with company alerts and requests.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final notif = list[index];
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
                notifIcon = Icons.check_circle_outline_rounded;
              } else if (notif.title.contains('Rejected')) {
                iconBg = AppColors.neoPink;
                notifIcon = Icons.cancel_outlined;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: notif.isRead
                      ? (isDark ? AppColors.surfaceDark : Colors.white)
                      : (isDark ? AppColors.surfaceDark : AppColors.neoYellow.withValues(alpha: 0.2)),
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
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                  contentPadding: const EdgeInsets.all(14),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Icon(notifIcon, color: AppColors.neoBorder, size: 20),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: GoogleFonts.outfit(
                            fontWeight: notif.isRead ? FontWeight.w700 : FontWeight.w900,
                            fontSize: 15,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.neoBorder,
                          ),
                        ),
                      ),
                      if (!notif.isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.neoPink,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.neoBorder),
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormatter.formatDateTime(notif.timestamp),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textSecondaryDark : Colors.grey[600],
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
