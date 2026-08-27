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
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        Color dotColor;
        IconData dotIcon;

        if (step.isCompleted) {
          dotColor = step.isRejected ? AppColors.statusRejected : AppColors.statusApproved;
          dotIcon = step.isRejected ? Icons.close_rounded : Icons.check_rounded;
        } else {
          dotColor = AppColors.statusPending;
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
                        color: dotColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: dotColor, width: 2),
                      ),
                      child: Icon(
                        dotIcon,
                        size: 16,
                        color: dotColor,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: step.isCompleted
                              ? dotColor.withValues(alpha: 0.4)
                              : Colors.grey.withValues(alpha: 0.3),
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
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (step.timestamp != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              DateFormatter.formatDateTime(step.timestamp!),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: Theme.of(context).brightness == Brightness.dark
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
                            color: Theme.of(context).brightness == Brightness.dark
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
                                : (Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.surfaceDark
                                    : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: step.isRejected
                                  ? AppColors.statusRejected.withValues(alpha: 0.3)
                                  : Colors.grey.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            step.comment!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: step.isRejected
                                  ? AppColors.statusRejected
                                  : null,
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
