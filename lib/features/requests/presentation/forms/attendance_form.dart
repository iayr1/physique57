import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class AttendanceForm extends ConsumerStatefulWidget {
  const AttendanceForm({super.key});

  @override
  ConsumerState<AttendanceForm> createState() => _AttendanceFormState();
}

class _AttendanceFormState extends ConsumerState<AttendanceForm> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _attendanceDate = DateTime.now();
  TimeOfDay _checkIn = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _checkOut = const TimeOfDay(hour: 18, minute: 0);
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _pickTime(bool isCheckIn) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isCheckIn ? _checkIn : _checkOut,
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
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
      requestType: RequestType.attendance,
      requestData: {
        'attendanceDate': DateFormatter.formatDateShort(_attendanceDate!),
        'checkInTime': _checkIn.format(context),
        'checkOutTime': _checkOut.format(context),
        'reason': _reasonController.text.trim(),
      },
      attachments: [],
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
          title: 'Manager Attendance Authorization',
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
            content: Text('Attendance Regularization ${result.requestId} submitted!'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Correction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CustomTextField(
              label: 'Attendance Date',
              readOnly: true,
              controller: TextEditingController(
                text: _attendanceDate != null
                    ? DateFormatter.formatDateShort(_attendanceDate!)
                    : '',
              ),
              suffixIcon: const Icon(Icons.calendar_today_rounded),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _attendanceDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 60)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _attendanceDate = picked);
              },
            ),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Check-In Time',
                    readOnly: true,
                    controller: TextEditingController(text: _checkIn.format(context)),
                    suffixIcon: const Icon(Icons.access_time_rounded),
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Check-Out Time',
                    readOnly: true,
                    controller: TextEditingController(text: _checkOut.format(context)),
                    suffixIcon: const Icon(Icons.access_time_filled_rounded),
                    onTap: () => _pickTime(false),
                  ),
                ),
              ],
            ),

            CustomTextField(
              label: 'Reason for Regularization',
              hint: 'e.g. Biometric scanner issue, client visit, forgot card...',
              controller: _reasonController,
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            const SizedBox(height: 24),
            CustomButton(
              text: 'Submit Regularization',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
