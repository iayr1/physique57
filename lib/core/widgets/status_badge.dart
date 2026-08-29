import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;

    Color textColor = AppColors.neoBorder;
    Color bgColor;
    IconData iconData;

    switch (status) {
      case RequestStatus.draft:
        textColor = isDark ? Colors.white : AppColors.neoBorder;
        bgColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
        iconData = Icons.edit_document;
        break;
      case RequestStatus.submitted:
        textColor = AppColors.neoBorder;
        bgColor = AppColors.neoCyan;
        iconData = Icons.send_rounded;
        break;
      case RequestStatus.pendingManagerApproval:
        textColor = AppColors.neoBorder;
        bgColor = AppColors.neoYellow;
        iconData = Icons.hourglass_top_rounded;
        break;
      case RequestStatus.pendingHrApproval:
        textColor = AppColors.neoBorder;
        bgColor = AppColors.neoPurple;
        iconData = Icons.badge_outlined;
        break;
      case RequestStatus.approved:
        textColor = AppColors.neoBorder;
        bgColor = AppColors.neoGreen;
        iconData = Icons.check_circle_rounded;
        break;
      case RequestStatus.rejected:
        textColor = Colors.white;
        bgColor = AppColors.statusRejected;
        iconData = Icons.cancel_rounded;
        break;
      case RequestStatus.cancelled:
        textColor = isDark ? Colors.white : AppColors.neoBorder;
        bgColor = isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1);
        iconData = Icons.block_rounded;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 13,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : AppColors.neoBorder,
            offset: const Offset(2, 2),
            blurRadius: 0,
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
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                compact ? status.compactDisplayName : status.displayName,
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
