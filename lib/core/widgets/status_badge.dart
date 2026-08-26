import 'package:flutter/material.dart';
import '../../features/requests/domain/request_status.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final RequestStatus status;
  final double fontSize;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12.0,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    Color borderColor;
    IconData iconData;

    switch (status) {
      case RequestStatus.draft:
        textColor = AppColors.textSecondaryLight;
        bgColor = AppColors.statusCancelledBg;
        borderColor = AppColors.statusCancelledBorder;
        iconData = Icons.edit_document;
        break;
      case RequestStatus.submitted:
        textColor = AppColors.statusSubmitted;
        bgColor = AppColors.statusSubmittedBg;
        borderColor = AppColors.statusSubmittedBorder;
        iconData = Icons.send_rounded;
        break;
      case RequestStatus.pendingManagerApproval:
        textColor = AppColors.statusPending;
        bgColor = AppColors.statusPendingBg;
        borderColor = AppColors.statusPendingBorder;
        iconData = Icons.hourglass_top_rounded;
        break;
      case RequestStatus.pendingHrApproval:
        textColor = const Color(0xFF7C3AED);
        bgColor = const Color(0xFFF5F3FF);
        borderColor = const Color(0xFFDDD6FE);
        iconData = Icons.badge_outlined;
        break;
      case RequestStatus.approved:
        textColor = AppColors.statusApproved;
        bgColor = AppColors.statusApprovedBg;
        borderColor = AppColors.statusApprovedBorder;
        iconData = Icons.check_circle_rounded;
        break;
      case RequestStatus.rejected:
        textColor = AppColors.statusRejected;
        bgColor = AppColors.statusRejectedBg;
        borderColor = AppColors.statusRejectedBorder;
        iconData = Icons.cancel_rounded;
        break;
      case RequestStatus.cancelled:
        textColor = AppColors.statusCancelled;
        bgColor = AppColors.statusCancelledBg;
        borderColor = AppColors.statusCancelledBorder;
        iconData = Icons.block_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: textColor.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            iconData,
            size: fontSize + 2,
            color: textColor,
          ),
          const SizedBox(width: 5),
          Text(
            status.displayName,
            style: TextStyle(
              color: textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
