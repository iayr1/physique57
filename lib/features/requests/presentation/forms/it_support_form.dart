import 'package:file_picker/file_picker.dart';
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

class ITSupportForm extends ConsumerStatefulWidget {
  const ITSupportForm({super.key});

  @override
  ConsumerState<ITSupportForm> createState() => _ITSupportFormState();
}

class _ITSupportFormState extends ConsumerState<ITSupportForm> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  final List<String> _issueCategories = [
    'Hardware Failure',
    'Software & Access Privileges',
    'VPN & Network Connectivity',
    'Email & Communication',
    'New Laptop / Peripheral Request',
    'Security Incident / Suspicious Email',
  ];

  final List<String> _deviceTypes = [
    'MacBook / Laptop',
    'Windows PC / Workstation',
    'Mobile Device (iOS/Android)',
    'Monitor & Accessories',
    'Printer / Scanner',
  ];

  final List<String> _priorities = [
    'Low - Minor inconvenience',
    'Medium - Impairs non-urgent work',
    'High - Work blocked entirely',
    'Critical - System outage / Emergency',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      ref.read(itSupportFormControllerProvider.notifier).setScreenshotName(result.files.first.name);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider).value;
    if (user == null) return;

    final formState = ref.read(itSupportFormControllerProvider);
    ref.read(itSupportFormControllerProvider.notifier).setSubmitting(true);

    final requestId = RequestIdGenerator.generate();
    final newRequest = RequestModel(
      requestId: requestId,
      employeeId: user.id,
      employeeName: user.name,
      employeeEmail: user.email,
      department: user.department,
      managerEmail: user.reportingManagerEmail,
      requestType: RequestType.itSupport,
      requestData: {
        'issueCategory': formState.issueCategory,
        'deviceType': formState.deviceType,
        'priority': formState.priority,
        'description': _descriptionController.text.trim(),
      },
      attachments: formState.screenshotName != null ? [formState.screenshotName!] : [],
      status: RequestStatus.pendingManagerApproval,
      submittedAt: DateTime.now(),
      approvalHistory: [
        ApprovalStepModel(
          title: 'Ticket Logged',
          actorName: user.name,
          actorRole: 'Employee',
          timestamp: DateTime.now(),
          isCompleted: true,
        ),
        ApprovalStepModel(
          title: 'IT Desk Triage & Resolution',
          actorRole: 'IT Support Engineer',
          timestamp: DateTime.now(),
          isCompleted: false,
        ),
      ],
    );

    final result = await ref.read(requestsProvider.notifier).submitNewRequest(newRequest);

    if (mounted) {
      ref.read(itSupportFormControllerProvider.notifier).setSubmitting(false);
      if (result != null) {
        context.push('/requests/${result.requestId}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('IT Ticket ${result.requestId} logged!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final itState = ref.watch(itSupportFormControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('IT Helpdesk Ticket', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Issue Category',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: itState.issueCategory,
              isExpanded: true,
              items: _issueCategories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.plusJakartaSans()))).toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(itSupportFormControllerProvider.notifier).setIssueCategory(v);
                }
              },
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 16),

            Text(
              'Device Type',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: itState.deviceType,
              isExpanded: true,
              items: _deviceTypes.map((d) => DropdownMenuItem(value: d, child: Text(d, style: GoogleFonts.plusJakartaSans()))).toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(itSupportFormControllerProvider.notifier).setDeviceType(v);
                }
              },
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 16),

            Text(
              'Priority Level',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: itState.priority,
              isExpanded: true,
              items: _priorities.map((p) => DropdownMenuItem(value: p, child: Text(p, style: GoogleFonts.plusJakartaSans()))).toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(itSupportFormControllerProvider.notifier).setPriority(v);
                }
              },
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Detailed Issue Description',
              hint: 'Explain what went wrong, error messages or steps to reproduce...',
              controller: _descriptionController,
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            Text(
              'Screenshot / Diagnostics Attachment',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickScreenshot,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_a_photo_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        itState.screenshotName ?? 'Attach error screenshot',
                        style: GoogleFonts.plusJakartaSans(
                          color: itState.screenshotName != null ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            CustomButton(
              text: 'Submit IT Ticket',
              isLoading: itState.isSubmitting,
              onPressed: _submitForm,
            ),
          ],
        ),
      ),
    );
  }
}
