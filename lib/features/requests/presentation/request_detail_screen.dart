import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/approval_timeline.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/request_provider.dart';
import '../../authentication/domain/employee_model.dart';
import '../domain/approval_step_model.dart';
import '../domain/request_category_model.dart';
import '../domain/request_model.dart';
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
    final currentUser = ref.watch(authProvider).valueOrNull;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final existingIndex = state.requests.indexWhere((r) => r.requestId == requestId);
    if (existingIndex != -1) {
      final request = state.requests[existingIndex];
      return _buildRequestScaffold(context, ref, request, currentUser, isDark);
    }

    return FutureBuilder<RequestModel>(
      future: ref.read(requestRepositoryProvider).getRequestById(requestId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text(requestId)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Request Details')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.description_outlined, size: 56, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'Request Not Found',
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The request "$requestId" has been processed or removed.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      label: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return _buildRequestScaffold(context, ref, snapshot.data!, currentUser, isDark);
      },
    );
  }

  Widget _buildRequestScaffold(
    BuildContext context,
    WidgetRef ref,
    RequestModel request,
    EmployeeModel? currentUser,
    bool isDark,
  ) {
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          size: 24,
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
                                fontSize: 17,
                                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Status',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        ),
                      ),
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

          // Admin / Manager Approval Buttons if Pending
          if ((request.status == RequestStatus.pendingManagerApproval ||
                  request.status == RequestStatus.pendingHrApproval) &&
              (currentUser?.isAdmin == true ||
                  currentUser?.email.toLowerCase() == request.managerEmail.toLowerCase())) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                    label: Text(
                      request.requestType == RequestType.leave ? 'Approve & Deduct' : 'Approve',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Approve Request?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                          content: Text(
                            request.requestType == RequestType.leave
                                ? 'Approve ${request.requestId} and automatically deduct ${request.requestData['numberOfDays'] ?? 1} day(s) from ${request.employeeName}\'s leave balance?'
                                : 'Are you sure you want to approve ${request.requestId}?',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Approve', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      try {
                        // 1. If Leave, deduct from employee leave balance in Firestore
                        if (request.requestType == RequestType.leave && request.employeeEmail.isNotEmpty) {
                          final leaveType = request.requestData['leaveType'] as String? ?? 'Annual / Paid Leave';
                          final days = (request.requestData['numberOfDays'] as num?)?.toInt() ?? 1;

                          final empRef = FirebaseFirestore.instance.collection('employees').doc(request.employeeEmail);
                          final empDoc = await empRef.get();
                          if (empDoc.exists && empDoc.data() != null) {
                            final emp = EmployeeModel.fromJson(empDoc.data()!);
                            final balances = Map<String, dynamic>.from(emp.leaveBalances);
                            final categoryQuota = Map<String, dynamic>.from(
                              balances[leaveType] ?? {'total': 18, 'used': 0, 'remaining': 18},
                            );

                            final currentRemaining = (categoryQuota['remaining'] as num?)?.toInt() ?? 18;
                            final currentUsed = (categoryQuota['used'] as num?)?.toInt() ?? 0;

                            categoryQuota['remaining'] = (currentRemaining - days).clamp(0, 999);
                            categoryQuota['used'] = currentUsed + days;
                            balances[leaveType] = categoryQuota;

                            await empRef.update({'leaveBalances': balances});
                          }
                        }

                        // 2. Update Request in Firestore
                        final newStep = ApprovalStepModel(
                          title: 'Approved by Administrator',
                          actorName: currentUser?.name ?? 'System Administrator',
                          actorRole: 'System Administrator',
                          timestamp: DateTime.now(),
                          isCompleted: true,
                          comment: 'Request approved successfully.',
                        );
                        final updatedHistory = [...request.approvalHistory, newStep];

                        await FirebaseFirestore.instance.collection('requests').doc(request.requestId).update({
                          'status': 'approved',
                          'approvalHistory': updatedHistory.map((s) => s.toJson()).toList(),
                        });

                        // 3. Send Notification
                        final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
                        await FirebaseFirestore.instance.collection('notifications').doc(notifId).set({
                          'id': notifId,
                          'title': 'Request Approved! ✅',
                          'message': 'Your ${request.requestType.title} request (${request.requestId}) was approved.',
                          'requestId': request.requestId,
                          'timestamp': Timestamp.now(),
                          'isRead': false,
                          'recipientEmail': request.employeeEmail,
                        });

                        await ref.read(requestsProvider.notifier).loadRequests();
                        await ref.read(authProvider.notifier).reloadUserProfile();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Request ${request.requestId} approved successfully!'),
                              backgroundColor: AppColors.statusApproved,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error approving request: $e'), backgroundColor: AppColors.statusRejected),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.cancel_outlined, color: Colors.white),
                    label: Text(
                      'Reject',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: () async {
                      final reasonController = TextEditingController();
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text('Reject Request', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Please provide a reason for rejecting ${request.requestId}:'),
                              const SizedBox(height: 12),
                              TextField(
                                controller: reasonController,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  hintText: 'e.g. Incomplete details, scheduling conflict...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Reject', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;
                      final reason = reasonController.text.trim().isEmpty ? 'Rejected by Administrator' : reasonController.text.trim();

                      try {
                        final newStep = ApprovalStepModel(
                          title: 'Rejected by Administrator',
                          actorName: currentUser?.name ?? 'System Administrator',
                          actorRole: 'System Administrator',
                          timestamp: DateTime.now(),
                          isCompleted: false,
                          isRejected: true,
                          comment: reason,
                        );
                        final updatedHistory = [...request.approvalHistory, newStep];

                        await FirebaseFirestore.instance.collection('requests').doc(request.requestId).update({
                          'status': 'rejected',
                          'rejectionReason': reason,
                          'approvalHistory': updatedHistory.map((s) => s.toJson()).toList(),
                        });

                        final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
                        await FirebaseFirestore.instance.collection('notifications').doc(notifId).set({
                          'id': notifId,
                          'title': 'Request Rejected ❌',
                          'message': 'Your ${request.requestType.title} request (${request.requestId}) was rejected. Reason: $reason',
                          'requestId': request.requestId,
                          'timestamp': Timestamp.now(),
                          'isRead': false,
                          'recipientEmail': request.employeeEmail,
                        });

                        await ref.read(requestsProvider.notifier).loadRequests();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Request ${request.requestId} rejected.'), backgroundColor: AppColors.statusRejected),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error rejecting: $e'), backgroundColor: AppColors.statusRejected),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // Cancel Request Button if Pending and current user is requester
          if ((request.status == RequestStatus.pendingManagerApproval ||
                  request.status == RequestStatus.pendingHrApproval) &&
              currentUser?.email == request.employeeEmail)
            CustomButton(
              text: 'Cancel My Request',
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
