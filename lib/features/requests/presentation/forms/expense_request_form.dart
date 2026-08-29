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

final expenseAmountInputProvider = StateProvider.autoDispose<String>((ref) => '');

class ExpenseRequestForm extends ConsumerStatefulWidget {
  const ExpenseRequestForm({super.key});

  @override
  ConsumerState<ExpenseRequestForm> createState() => _ExpenseRequestFormState();
}

class _ExpenseRequestFormState extends ConsumerState<ExpenseRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _categories = [
    'Travel & Lodging',
    'Client Entertainment',
    'Software / Cloud Subscription',
    'Hardware & Electronics',
    'Office Supplies',
    'Training & Certification',
    'Other Expenses',
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() {
      ref.read(expenseAmountInputProvider.notifier).state = _amountController.text;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result != null && result.files.isNotEmpty) {
      ref.read(expenseFormControllerProvider.notifier).setReceiptName(result.files.first.name);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(authProvider).value;
    if (user == null) return;

    final formState = ref.read(expenseFormControllerProvider);
    ref.read(expenseFormControllerProvider.notifier).setSubmitting(true);

    final requestId = RequestIdGenerator.generate();
    final amountDouble = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final newRequest = RequestModel(
      requestId: requestId,
      employeeId: user.id,
      employeeName: user.name,
      employeeEmail: user.email,
      department: user.department,
      managerEmail: user.reportingManagerEmail,
      requestType: RequestType.expense,
      requestData: {
        'category': formState.category,
        'amount': '₹${amountDouble.toStringAsFixed(2)}',
        'expenseDate': DateFormatter.formatDateShort(formState.expenseDate ?? DateTime.now()),
        'description': _descriptionController.text.trim(),
      },
      attachments: formState.receiptName != null ? [formState.receiptName!] : [],
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
        ApprovalStepModel(
          title: 'Finance Reimbursement',
          actorRole: 'Finance Dept',
          isCompleted: false,
        ),
      ],
    );

    final result = await ref.read(requestsProvider.notifier).submitNewRequest(newRequest);

    if (mounted) {
      ref.read(expenseFormControllerProvider.notifier).setSubmitting(false);
      if (result != null) {
        context.push('/requests/${result.requestId}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Expense Claim ${result.requestId} submitted!'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseFormControllerProvider);
    final amountInput = ref.watch(expenseAmountInputProvider);
    final rawAmount = double.tryParse(amountInput.trim()) ?? 0.0;
    final baseAmount = rawAmount / 1.18;
    final gstAmount = rawAmount - baseAmount;

    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Reimbursement', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Expense Category',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: expenseState.category,
              isExpanded: true,
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c, style: GoogleFonts.plusJakartaSans())))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  ref.read(expenseFormControllerProvider.notifier).setCategory(v);
                }
              },
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: 'Total Amount (₹ INR)',
                    hint: '0.00',
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: const Icon(Icons.currency_rupee_rounded),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter amount';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: 'Expense Date',
                    readOnly: true,
                    controller: TextEditingController(
                      text: expenseState.expenseDate != null
                          ? DateFormatter.formatDateShort(expenseState.expenseDate!)
                          : '',
                    ),
                    suffixIcon: const Icon(Icons.calendar_month_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: expenseState.expenseDate ?? DateTime.now(),
                        firstDate: DateTime(2025),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        ref.read(expenseFormControllerProvider.notifier).setExpenseDate(picked);
                      }
                    },
                  ),
                ),
              ],
            ),

            // Automated Tax & Total Breakdown Box
            if (rawAmount > 0) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Base Pre-Tax Amount:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('₹${baseAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated GST (18%):', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('₹${gstAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                      ],
                    ),
                    const Divider(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Reimbursement:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('₹${rawAmount.toStringAsFixed(2)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            CustomTextField(
              label: 'Expense Description & Justification',
              hint: 'Itemize products or business purpose...',
              controller: _descriptionController,
              maxLines: 3,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),

            Text(
              'Receipt / Invoice Upload',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickReceipt,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        expenseState.receiptName ?? 'Attach receipt (PDF, PNG, JPG)',
                        style: GoogleFonts.plusJakartaSans(
                          color: expenseState.receiptName != null ? AppColors.textPrimaryLight : AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            CustomButton(
              text: 'Submit Expense Claim',
              isLoading: expenseState.isSubmitting,
              onPressed: _submitForm,
            ),
          ],
        ),
      ),
    );
  }
}
