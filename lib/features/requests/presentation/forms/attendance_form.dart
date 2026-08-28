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
import 'controllers/form_controllers.dart';

class AttendanceForm extends ConsumerStatefulWidget {
  const AttendanceForm({super.key});

  @override
  ConsumerState<AttendanceForm> createState() => _AttendanceFormState();
}

class _AttendanceFormState extends ConsumerState<AttendanceForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isCheckIn) async {
    final formState = ref.read(attendanceFormControllerProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: isCheckIn ? formState.checkIn : formState.checkOut,
    );
    if (picked != null) {
      if (isCheckIn) {
        ref.read(attendanceFormControllerProvider.notifier).setCheckIn(picked);
      } else {
        ref.read(attendanceFormControllerProvider.notifier).setCheckOut(picked);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider).value;
    if (user == null) return;

    final formState = ref.read(attendanceFormControllerProvider);
    ref.read(attendanceFormControllerProvider.notifier).setSubmitting(true);

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
        'attendanceDate': DateFormatter.formatDateShort(formState.attendanceDate ?? DateTime.now()),
        'checkInTime': formState.checkIn.format(context),
        'checkOutTime': formState.checkOut.format(context),
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
      ref.read(attendanceFormControllerProvider.notifier).setSubmitting(false);
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
    final formState = ref.watch(attendanceFormControllerProvider);

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
                text: formState.attendanceDate != null
                    ? DateFormatter.formatDateShort(formState.attendanceDate!)
                    : '',
              ),
              suffixIcon: const Icon(Icons.calendar_today_rounded),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: formState.attendanceDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 60)),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  ref.read(attendanceFormControllerProvider.notifier).setAttendanceDate(picked);
                }
              },
            ),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Check-In Time',
                    readOnly: true,
                    controller: TextEditingController(text: formState.checkIn.format(context)),
                    suffixIcon: const Icon(Icons.access_time_rounded),
                    onTap: () => _pickTime(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Check-Out Time',
                    readOnly: true,
                    controller: TextEditingController(text: formState.checkOut.format(context)),
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
              isLoading: formState.isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
