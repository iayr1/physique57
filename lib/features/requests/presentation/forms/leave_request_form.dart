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

class LeaveRequestForm extends ConsumerStatefulWidget {
  const LeaveRequestForm({super.key});

  @override
  ConsumerState<LeaveRequestForm> createState() => _LeaveRequestFormState();
}

class _LeaveRequestFormState extends ConsumerState<LeaveRequestForm> {
  final _formKey = GlobalKey<FormState>();
  String _leaveType = 'Annual / Paid Leave';
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  String? _attachmentName;
  bool _isSubmitting = false;

  final List<String> _leaveTypes = [
    'Annual / Paid Leave',
    'Casual Leave',
    'Sick Leave',
    'Maternity / Paternity Leave',
    'Bereavement Leave',
    'Unpaid Leave',
  ];

  int get _numberOfDays {
    if (_startDate != null && _endDate != null) {
      return DateFormatter.calculateDaysBetween(_startDate!, _endDate!);
    }
    return 0;
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _attachmentName = result.files.first.name;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select valid start and end dates')),
      );
      return;
    }

    final user = ref.read(authProvider).value;
    if (user == null) return;

    setState(() => _isSubmitting = true);

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
        'leaveType': _leaveType,
        'startDate': DateFormatter.formatDateShort(_startDate!),
        'endDate': DateFormatter.formatDateShort(_endDate!),
        'numberOfDays': _numberOfDays,
        'reason': _reasonController.text.trim(),
      },
      attachments: _attachmentName != null ? [_attachmentName!] : [],
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
      setState(() => _isSubmitting = false);
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
    final user = ref.watch(authProvider).value;

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
              initialValue: _leaveType,
              items: _leaveTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.plusJakartaSans())))
                  .toList(),
              onChanged: (val) => setState(() => _leaveType = val!),
              decoration: const InputDecoration(),
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
                      text: _startDate != null
                          ? DateFormatter.formatDateShort(_startDate!)
                          : '',
                    ),
                    suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                    onTap: () => _pickDate(true),
                    validator: (v) => _startDate == null ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'End Date',
                    hint: 'Select Date',
                    readOnly: true,
                    controller: TextEditingController(
                      text: _endDate != null
                          ? DateFormatter.formatDateShort(_endDate!)
                          : '',
                    ),
                    suffixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                    onTap: () => _pickDate(false),
                    validator: (v) => _endDate == null ? 'Required' : null,
                  ),
                ),
              ],
            ),

            // Automatically Calculated Days Box
            if (_numberOfDays > 0)
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
                      'Total Duration: $_numberOfDays Working Day${_numberOfDays > 1 ? "s" : ""}',
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
                        _attachmentName ?? 'Upload medical certificate or supporting document',
                        style: GoogleFonts.plusJakartaSans(
                          color: _attachmentName != null ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
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
              isLoading: _isSubmitting,
              onPressed: _submitForm,
            ),
          ],
        ),
      ),
    );
  }
}
