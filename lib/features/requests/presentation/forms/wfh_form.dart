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

class WFHForm extends ConsumerStatefulWidget {
  const WFHForm({super.key});

  @override
  ConsumerState<WFHForm> createState() => _WFHFormState();
}

class _WFHFormState extends ConsumerState<WFHForm> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final formState = ref.read(wfhFormControllerProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: formState.startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      if (isStart) {
        ref.read(wfhFormControllerProvider.notifier).setStartDate(picked);
        if (formState.endDate != null && formState.endDate!.isBefore(picked)) {
          ref.read(wfhFormControllerProvider.notifier).setEndDate(picked);
        }
      } else {
        ref.read(wfhFormControllerProvider.notifier).setEndDate(picked);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final formState = ref.read(wfhFormControllerProvider);
    if (formState.startDate == null || formState.endDate == null) return;
    final user = ref.read(authProvider).value;
    if (user == null) return;

    ref.read(wfhFormControllerProvider.notifier).setSubmitting(true);

    final requestId = RequestIdGenerator.generate();
    final newRequest = RequestModel(
      requestId: requestId,
      employeeId: user.id,
      employeeName: user.name,
      employeeEmail: user.email,
      department: user.department,
      managerEmail: user.reportingManagerEmail,
      requestType: RequestType.workFromHome,
      requestData: {
        'startDate': DateFormatter.formatDateShort(formState.startDate!),
        'endDate': DateFormatter.formatDateShort(formState.endDate!),
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
          title: 'Manager Approval Required',
          actorName: user.reportingManagerName,
          actorRole: 'Reporting Manager',
          timestamp: DateTime.now(),
          isCompleted: false,
        ),
      ],
    );

    final result = await ref.read(requestsProvider.notifier).submitNewRequest(newRequest);

    if (mounted) {
      ref.read(wfhFormControllerProvider.notifier).setSubmitting(false);
      if (result != null) {
        context.push('/requests/${result.requestId}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WFH Request ${result.requestId} submitted!'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(wfhFormControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Work From Home Request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Start Date',
                    readOnly: true,
                    controller: TextEditingController(
                      text: formState.startDate != null
                          ? DateFormatter.formatDateShort(formState.startDate!)
                          : '',
                    ),
                    suffixIcon: const Icon(Icons.calendar_month_rounded),
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'End Date',
                    readOnly: true,
                    controller: TextEditingController(
                      text: formState.endDate != null
                          ? DateFormatter.formatDateShort(formState.endDate!)
                          : '',
                    ),
                    suffixIcon: const Icon(Icons.calendar_month_rounded),
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),

            CustomTextField(
              label: 'Work From Home Reason',
              hint: 'Provide context for working remotely...',
              controller: _reasonController,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            const SizedBox(height: 24),
            CustomButton(
              text: 'Submit WFH Request',
              isLoading: formState.isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
