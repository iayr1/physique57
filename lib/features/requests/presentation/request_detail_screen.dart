import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/approval_timeline.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/request_provider.dart';
import '../domain/request_status.dart';

class RequestDetailScreen extends ConsumerWidget {
  final String requestId;

  const RequestDetailScreen({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(requestsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final request = state.requests.firstWhere(
      (r) => r.requestId == requestId,
      orElse: () => throw Exception('Request not found'),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(request.requestId, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied link for ${request.requestId}')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
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
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: request.requestType.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: request.requestType.color.withValues(alpha: 0.2)),
                              ),
                              child: Icon(
                                request.requestType.icon,
                                color: request.requestType.color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.requestType.title,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                    ),
                                  ),
                                  Text(
                                    'Submitted ${DateFormatter.formatDateTime(request.submittedAt)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(status: request.status),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Rejection Callout Box if Rejected
          if (request.status == RequestStatus.rejected && request.rejectionReason != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.statusRejectedBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.statusRejectedBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.report_problem_rounded, color: AppColors.statusRejected),
                      const SizedBox(width: 8),
                      Text(
                        'Request Rejected',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.statusRejected,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reason: ${request.rejectionReason}',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.statusRejected,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Details Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Details',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Divider(height: 24, color: Color(0xFFF1F5F9)),
                  _buildDetailRow('Employee Name', request.employeeName),
                  _buildDetailRow('Employee ID', request.employeeId),
                  _buildDetailRow('Department', request.department),
                  _buildDetailRow('Reporting Manager', request.managerEmail),

                  // Dynamic Request Fields
                  ...request.requestData.entries.map((entry) {
                    return _buildDetailRow(
                      _formatKeyName(entry.key),
                      entry.value.toString(),
                    );
                  }),

                  if (request.attachments.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Attachments',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondaryLight),
                    ),
                    const SizedBox(height: 6),
                    ...request.attachments.map((file) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.insert_drive_file_outlined, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                file,
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                            const Icon(Icons.download_rounded, size: 18, color: Colors.grey),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Visual Approval Timeline Tracker Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approval Timeline & History',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ApprovalTimeline(steps: request.approvalHistory),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Cancel Request Button if Pending
          if (request.status == RequestStatus.pendingManagerApproval ||
              request.status == RequestStatus.pendingHrApproval)
            CustomButton(
              text: 'Cancel Request',
              isOutlined: true,
              backgroundColor: AppColors.statusRejected,
              textColor: AppColors.statusRejected,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Cancel Request?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                    content: Text('Are you sure you want to cancel ${request.requestId}?', style: GoogleFonts.plusJakartaSans()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text('No', style: GoogleFonts.plusJakartaSans()),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text('Yes, Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.statusRejected, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await ref.read(requestsProvider.notifier).cancelRequest(request.requestId);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.textSecondaryLight,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatKeyName(String key) {
    return key
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .toUpperCase()
        .replaceFirst(key[0].toUpperCase(), key[0].toUpperCase());
  }
}
