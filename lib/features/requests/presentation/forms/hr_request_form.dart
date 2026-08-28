import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
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

class HRRequestForm extends ConsumerStatefulWidget {
  const HRRequestForm({super.key});

  @override
  ConsumerState<HRRequestForm> createState() => _HRRequestFormState();
}

class _HRRequestFormState extends ConsumerState<HRRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _categories = [
    'Employment Letter / Verification',
    'Payroll / Salary Query',
    'Benefits & Insurance Claim',
    'Performance & Appraisal Query',
    'Company Policy Clarification',
    'General HR Ticket',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider).value;
    if (user == null) return;

    final formState = ref.read(hrFormControllerProvider);
    ref.read(hrFormControllerProvider.notifier).setSubmitting(true);

    final requestId = RequestIdGenerator.generate();
    final newRequest = RequestModel(
      requestId: requestId,
      employeeId: user.id,
      employeeName: user.name,
      employeeEmail: user.email,
      department: user.department,
      managerEmail: user.reportingManagerEmail,
      requestType: RequestType.hrRequest,
      requestData: {
        'category': formState.category,
        'subject': _subjectController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isConfidential': formState.isConfidential ? 'Yes' : 'No',
      },
      attachments: [],
      status: RequestStatus.pendingHrApproval,
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
          title: 'HR Department Review',
          actorRole: 'HR Operations',
          timestamp: DateTime.now(),
          isCompleted: false,
        ),
      ],
    );

    final result = await ref.read(requestsProvider.notifier).submitNewRequest(newRequest);

    if (mounted) {
      ref.read(hrFormControllerProvider.notifier).setSubmitting(false);
      if (result != null) {
        context.push('/requests/${result.requestId}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('HR Inquiry ${result.requestId} submitted!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hrState = ref.watch(hrFormControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text('HR Request & Inquiry', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Inquiry Category',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: hrState.category,
              isExpanded: true,
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.plusJakartaSans(), overflow: TextOverflow.ellipsis))).toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(hrFormControllerProvider.notifier).setCategory(v);
                }
              },
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Subject',
              hint: 'Brief summary of inquiry...',
              controller: _subjectController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            CustomTextField(
              label: 'Full Details / Description',
              hint: 'State your question or request details clearly...',
              controller: _descriptionController,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            SwitchListTile(
              title: Text('Mark as Confidential', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
              subtitle: Text('Only accessible by HR Operations Leads', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.textSecondaryLight)),
              value: hrState.isConfidential,
              activeThumbColor: AppColors.primary,
              onChanged: (val) => ref.read(hrFormControllerProvider.notifier).setConfidential(val),
            ),

            const SizedBox(height: 24),
            CustomButton(
              text: 'Submit HR Ticket',
              isLoading: hrState.isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
