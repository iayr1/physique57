import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/requests/domain/approval_step_model.dart';
import '../constants/app_colors.dart';
import '../utils/date_formatter.dart';

class ApprovalTimeline extends StatelessWidget {
  final List<ApprovalStepModel> steps;

  const ApprovalTimeline({
    super.key,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white : AppColors.neoBorder;

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        Color dotColor;
        IconData dotIcon;

        if (step.isCompleted) {
          dotColor = step.isRejected ? AppColors.statusRejected : AppColors.neoGreen;
          dotIcon = step.isRejected ? Icons.close_rounded : Icons.check_rounded;
        } else {
          dotColor = AppColors.neoYellow;
          dotIcon = Icons.access_time_rounded;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Column (Dot + Line)
              SizedBox(
                width: 32,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: dotColor,
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
                      child: Icon(
                        dotIcon,
                        size: 16,
                        color: AppColors.neoBorder,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2.5,
                          color: borderColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Content Column
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              step.title,
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : AppColors.neoBorder,
                              ),
                            ),
                          ),
                          if (step.timestamp != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              DateFormatter.formatDateTime(step.timestamp!),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (step.actorName != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${step.actorRole ?? "Assigned"}: ${step.actorName}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                      if (step.comment != null && step.comment!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: step.isRejected
                                ? AppColors.statusRejectedBg
                                : (isDark ? AppColors.surfaceDark : Colors.white),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: borderColor,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: borderColor,
                                offset: const Offset(2, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            step.comment!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              color: step.isRejected
                                  ? AppColors.statusRejected
                                  : (isDark ? Colors.white : AppColors.neoBorder),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
