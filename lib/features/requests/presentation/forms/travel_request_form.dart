import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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

class TravelRequestForm extends ConsumerStatefulWidget {
  const TravelRequestForm({super.key});

  @override
  ConsumerState<TravelRequestForm> createState() => _TravelRequestFormState();
}

class _TravelRequestFormState extends ConsumerState<TravelRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _purposeController = TextEditingController();
  final _budgetController = TextEditingController();

  final List<String> _modes = [
    'Flight (Economy)',
    'Flight (Business Class - Director+)',
    'Train / Express Rail',
    'Rental Car / Taxi',
    'Personal Vehicle (Reimbursed)',
  ];

  @override
  void dispose() {
    _destinationController.dispose();
    _purposeController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final formState = ref.read(travelFormControllerProvider);
    if (formState.startDate == null || formState.endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select departure and return dates')),
      );
      return;
    }

    final user = ref.read(authProvider).value;
    if (user == null) return;

    ref.read(travelFormControllerProvider.notifier).setSubmitting(true);

    final requestId = RequestIdGenerator.generate();
    final newRequest = RequestModel(
      requestId: requestId,
      employeeId: user.id,
      employeeName: user.name,
      employeeEmail: user.email,
      department: user.department,
      managerEmail: user.reportingManagerEmail,
      requestType: RequestType.travel,
      requestData: {
        'destination': _destinationController.text.trim(),
        'purpose': _purposeController.text.trim(),
        'departureDate': DateFormatter.formatDateShort(formState.startDate!),
        'returnDate': DateFormatter.formatDateShort(formState.endDate!),
        'travelMode': formState.travelMode,
        'estimatedBudget': _budgetController.text.isNotEmpty ? '\$${_budgetController.text}' : 'N/A',
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
          title: 'Manager Travel Authorization',
          actorName: user.reportingManagerName,
          actorRole: 'Reporting Manager',
          timestamp: DateTime.now(),
          isCompleted: false,
        ),
        ApprovalStepModel(
          title: 'Travel Desk Booking',
          actorRole: 'Corporate Travel Team',
          isCompleted: false,
        ),
      ],
    );

    final result = await ref.read(requestsProvider.notifier).submitNewRequest(newRequest);

    if (mounted) {
      ref.read(travelFormControllerProvider.notifier).setSubmitting(false);
      if (result != null) {
        context.push('/requests/${result.requestId}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Travel Authorization ${result.requestId} submitted!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(travelFormControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Business Travel Authorization', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            CustomTextField(
              label: 'Destination City & Country',
              hint: 'e.g. London, UK or Singapore HQ',
              controller: _destinationController,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            CustomTextField(
              label: 'Business Purpose',
              hint: 'Client meeting, conference, onsite project...',
              controller: _purposeController,
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Departure Date',
                    readOnly: true,
                    controller: TextEditingController(
                      text: formState.startDate != null ? DateFormatter.formatDateShort(formState.startDate!) : '',
                    ),
                    suffixIcon: const Icon(Icons.flight_takeoff_rounded),
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (p != null) {
                        ref.read(travelFormControllerProvider.notifier).setStartDate(p);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Return Date',
                    readOnly: true,
                    controller: TextEditingController(
                      text: formState.endDate != null ? DateFormatter.formatDateShort(formState.endDate!) : '',
                    ),
                    suffixIcon: const Icon(Icons.flight_land_rounded),
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: formState.startDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (p != null) {
                        ref.read(travelFormControllerProvider.notifier).setEndDate(p);
                      }
                    },
                  ),
                ),
              ],
            ),

            Text(
              'Preferred Travel Mode',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: formState.travelMode,
              isExpanded: true,
              items: _modes.map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.plusJakartaSans()))).toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(travelFormControllerProvider.notifier).setTravelMode(v);
                }
              },
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 16),

            CustomTextField(
              label: 'Estimated Travel Cost / Budget (\$)',
              hint: 'e.g. 1200.00',
              controller: _budgetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.attach_money_rounded),
            ),

            const SizedBox(height: 24),
            CustomButton(
              text: 'Submit Travel Request',
              isLoading: formState.isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
