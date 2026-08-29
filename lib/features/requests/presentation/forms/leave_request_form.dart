import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/request_id_generator.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/request_provider.dart';
import '../../domain/approval_step_model.dart';
import '../../domain/request_category_model.dart';
import '../../domain/request_model.dart';
import '../../domain/request_status.dart';
import 'controllers/form_controllers.dart';

class LeaveRequestForm extends ConsumerStatefulWidget {
  const LeaveRequestForm({super.key});

  @override
  ConsumerState<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends ConsumerState<LeaveRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  final List<String> _leaveTypes = [
    'Annual / Paid Leave',
    'Casual Leave',
    'Sick Leave',
    'Maternity / Paternity Leave',
    'Bereavement Leave',
    'Unpaid Leave',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int _calculateDays(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      int count = 0;
      DateTime cur = start;
      while (!cur.isAfter(end)) {
        if (cur.weekday != DateTime.saturday && cur.weekday != DateTime.sunday) {
          count++;
        }
        cur = cur.add(const Duration(days: 1));
      }
      return count > 0 ? count : 1;
    }
    return 0;
  }

  Future<void> _pickDate(bool isStart) async {
    final formState = ref.read(leaveFormControllerProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: formState.startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      if (isStart) {
        ref.read(leaveFormControllerProvider.notifier).setStartDate(picked);
        if (formState.endDate != null && formState.endDate!.isBefore(picked)) {
          ref.read(leaveFormControllerProvider.notifier).setEndDate(picked);
        }
      } else {
        ref.read(leaveFormControllerProvider.notifier).setEndDate(picked);
      }
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg'],
    );
    if (result != null && result.files.isNotEmpty) {
      ref.read(leaveFormControllerProvider.notifier).setAttachmentName(result.files.first.name);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final formState = ref.read(leaveFormControllerProvider);
    if (formState.startDate == null || formState.endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select valid start and end dates')),
      );
      return;
    }

    final user = ref.read(authProvider).value;
    if (user == null) return;

    final numDays = _calculateDays(formState.startDate, formState.endDate);
    final remaining = user.getRemainingLeave(formState.leaveType);
    if (formState.leaveType != 'Unpaid Leave' && numDays > remaining) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient leave balance! You requested $numDays day(s), but only have $remaining day(s) remaining for ${formState.leaveType}. Please choose fewer days or select Unpaid Leave.',
          ),
          backgroundColor: AppColors.statusRejected,
        ),
      );
      return;
    }

    ref.read(leaveFormControllerProvider.notifier).setSubmitting(true);

    final requestId = RequestIdGenerator.generate();
    final newRequest = RequestModel(
      requestId: requestId,
      employeeId: user.id,
      employeeName: user.name,
      employeeEmail: user.email,
      department: user.department,
      managerEmail: user.reportingManagerEmail,
      requestType: RequestType.leave,
      requestData: {
        'leaveType': formState.leaveType,
        'startDate': DateFormatter.formatDateShort(formState.startDate!),
        'endDate': DateFormatter.formatDateShort(formState.endDate!),
        'numberOfDays': numDays,
        'reason': _reasonController.text.trim(),
      },
      attachments: formState.attachmentName != null ? [formState.attachmentName!] : [],
      status: RequestStatus.pendingManagerApproval,
      submittedAt: DateTime.now(),
      approvalHistory: [
        ApprovalStepModel(
          title: 'Request Submitted',
          actorName: user.name,
          actorRole: 'Employee',
          timestamp: DateTime.now(),
          isCompleted: true,
        ),
        ApprovalStepModel(
          title: 'Pending Manager Approval',
          actorName: user.reportingManagerName,
          actorRole: 'Reporting Manager',
          timestamp: DateTime.now(),
          isCompleted: false,
        ),
      ],
    );

    final result = await ref.read(requestsProvider.notifier).submitNewRequest(newRequest);

    if (mounted) {
      ref.read(leaveFormControllerProvider.notifier).setSubmitting(false);
      if (result != null) {
        context.push('/requests/${result.requestId}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leave Request ${result.requestId} submitted successfully!'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(leaveFormControllerProvider);
    final user = ref.watch(authProvider).value;
    final remainingDays = user?.getRemainingLeave(leaveState.leaveType) ?? 0;
    final totalDays = user?.getTotalLeave(leaveState.leaveType) ?? 0;
    final usedDays = user?.getUsedLeave(leaveState.leaveType) ?? 0;
    final numberOfDays = _calculateDays(leaveState.startDate, leaveState.endDate);

    return Scaffold(
      appBar: AppBar(
        title: Text('New Leave Request', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // User Prefilled Info Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? '',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'ID: ${user?.id ?? ''} • ${user?.department ?? ''}',
                            style: GoogleFonts.plusJakartaSans(color: AppColors.textSecondaryLight, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Dropdown Leave Type
            Text(
              'Leave Type',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: leaveState.leaveType,
              isExpanded: true,
              items: _leaveTypes
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(t, style: GoogleFonts.plusJakartaSans()),
                      ))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(leaveFormControllerProvider.notifier).setLeaveType(val);
                }
              },
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 8),

            // Live Quota Indicator Badge
            if (leaveState.leaveType != 'Unpaid Leave')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: remainingDays > 0 ? Colors.green.withValues(alpha: 0.08) : Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: remainingDays > 0 ? Colors.green.withValues(alpha: 0.25) : Colors.red.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(
                      remainingDays > 0 ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                      size: 18,
                      color: remainingDays > 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quota: $remainingDays / $totalDays Days Remaining (Used: $usedDays)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: remainingDays > 0 ? Colors.green[800] : Colors.red[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Date Pickers Row
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Start Date',
                    hint: 'Select Date',
                    readOnly: true,
                    controller: TextEditingController(
                      text: leaveState.startDate != null
                          ? DateFormatter.formatDateShort(leaveState.startDate!)
                          : '',
                    ),
                    suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                    onTap: () => _pickDate(true),
                    validator: (v) => leaveState.startDate == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'End Date',
                    hint: 'Select Date',
                    readOnly: true,
                    controller: TextEditingController(
                      text: leaveState.endDate != null
                          ? DateFormatter.formatDateShort(leaveState.endDate!)
                          : '',
                    ),
                    suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                    onTap: () => _pickDate(false),
                    validator: (v) => leaveState.endDate == null ? 'Required' : null,
                  ),
                ),
              ],
            ),

            // Automatically Calculated Days Box
            if (numberOfDays > 0)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Total Duration: $numberOfDays Working Day${numberOfDays > 1 ? "s" : ""}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

            CustomTextField(
              label: 'Reason for Leave',
              hint: 'Describe why you are taking leave...',
              controller: _reasonController,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a reason' : null,
            ),

            // Attachment Section
            Text(
              'Attachment (Optional)',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickAttachment,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        leaveState.attachmentName ?? 'Upload medical certificate or supporting document',
                        style: GoogleFonts.plusJakartaSans(
                          color: leaveState.attachmentName != null ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            CustomButton(
              text: 'Submit Leave Request',
              isLoading: leaveState.isSubmitting,
              onPressed: _submitForm,
            ),
          ],
        ),
      ),
    );
  }
}
