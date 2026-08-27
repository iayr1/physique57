import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../features/admin/domain/task_model.dart';
import '../../../features/authentication/domain/employee_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0; // 0 = Overview, 1 = Onboarding, 2 = Requests, 3 = Attendance, 4 = Tasks
  bool _isLoading = false;

  // Onboarding Form Controllers
  final _onboardFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _deptController = TextEditingController();
  final _designationController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _managerEmailController = TextEditingController();

  // Task Form Controllers
  final _taskFormKey = GlobalKey<FormState>();
  final _taskTitleController = TextEditingController();
  final _taskDescController = TextEditingController();
  String? _taskAssigneeEmail;
  String? _taskAssigneeName;
  final DateTime _taskDueDate = DateTime.now().add(const Duration(days: 2));

  // Directory Search Controller
  final _searchDirectoryController = TextEditingController();
  String _searchDirectoryQuery = '';

  // Attendance State
  DateTime _selectedAttendanceDate = DateTime.now();
  final _searchAttendanceController = TextEditingController();
  String _attendanceSearchQuery = '';
  String _attendanceFilterStatus = 'All'; // 'All', 'Present', 'Late', 'Not Checked In'
  int _attendanceTabMode = 0; // 0 = All Employees Status, 1 = Full Attendance Log

  // Announcement Controllers
  final _announcementTitleCtrl = TextEditingController();
  final _announcementMsgCtrl = TextEditingController();
  String _announcementPriority = 'Normal';

  // Audit Search Controller
  final _auditSearchCtrl = TextEditingController();
  String _auditSearchQuery = '';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _deptController.dispose();
    _designationController.dispose();
    _managerNameController.dispose();
    _managerEmailController.dispose();
    _taskTitleController.dispose();
    _taskDescController.dispose();
    _searchDirectoryController.dispose();
    _searchAttendanceController.dispose();
    _announcementTitleCtrl.dispose();
    _announcementMsgCtrl.dispose();
    _auditSearchCtrl.dispose();
    super.dispose();
  }

  // Toggle Employee Login Activation / Deactivation
  Future<void> _toggleEmployeeStatus(String email, String name, bool currentIsActive) async {
    final newStatus = !currentIsActive;
    final actionName = newStatus ? 'Activate' : 'Deactivate';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$actionName App Login?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text(
          newStatus
              ? 'Are you sure you want to activate login access for $name ($email)? They will be able to log in to the app.'
              : 'Are you sure you want to deactivate login access for $name ($email)? They will be immediately blocked from logging in.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('employees').doc(email).update({
        'isActive': newStatus,
        'status': newStatus ? 'active' : 'deactivated',
      });

      // Send notification
      final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance.collection('notifications').doc(notifId).set({
        'id': notifId,
        'title': newStatus ? 'Account Activated' : 'Account Deactivated',
        'message': newStatus
            ? 'Your employee app access has been activated by the administrator.'
            : 'Your employee app access has been temporarily deactivated by the administrator.',
        'requestId': '',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'recipientEmail': email,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name\'s login is now ${newStatus ? "ACTIVATED" : "DEACTIVATED"}.'),
            backgroundColor: newStatus ? AppColors.statusApproved : AppColors.statusRejected,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppColors.statusRejected),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Delete Employee Profile
  Future<void> _deleteEmployee(String docId, String name, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 26),
            const SizedBox(width: 8),
            Text('Delete Employee', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text('Are you sure you want to permanently delete $name ($email)? Their profile and leave balances will be removed from Firestore.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Permanently', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('employees').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ $name has been removed from user directory'), backgroundColor: AppColors.statusApproved),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e'), backgroundColor: AppColors.statusRejected),
        );
      }
    }
  }

  // Change Password for User
  Future<void> _changeUserPassword(String email, String name) async {
    final passwordController = TextEditingController();
    bool sendEmailLink = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Change Password: $name',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select how you want to update credentials for $email:',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          value: true,
                          groupValue: sendEmailLink,
                          title: Text('Send Password Setup / Reset Email', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text('Dispatches official Firebase reset link to $email', style: GoogleFonts.plusJakartaSans(fontSize: 11)),
                          onChanged: (v) => setModalState(() => sendEmailLink = v!),
                        ),
                        const Divider(height: 1),
                        RadioListTile<bool>(
                          value: false,
                          groupValue: sendEmailLink,
                          title: Text('Set New Temporary Password', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                          subtitle: Text('Admin manually defines a new temporary password', style: GoogleFonts.plusJakartaSans(fontSize: 11)),
                          onChanged: (v) => setModalState(() => sendEmailLink = v!),
                        ),
                      ],
                    ),
                  ),
                  if (!sendEmailLink) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: passwordController,
                            decoration: const InputDecoration(
                              labelText: 'New Temporary Password',
                              hintText: 'e.g. Emp@58291',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Generate', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            final rand = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
                            passwordController.text = 'Emp@$rand';
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);

                  try {
                    if (sendEmailLink) {
                      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('✓ Password reset link successfully sent to $email ($name)!'),
                          backgroundColor: AppColors.statusApproved,
                        ),
                      );
                    } else {
                      final newPass = passwordController.text.trim();
                      if (newPass.length < 6) {
                        messenger.showSnackBar(
                          const SnackBar(content: Text('Password must be at least 6 characters'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      // Send notification to employee
                      final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
                      try {
                        await FirebaseFirestore.instance.collection('notifications').doc(notifId).set({
                          'id': notifId,
                          'title': 'Password Updated by Administrator',
                          'message': 'Your account credentials were reset. Your new temporary password is: $newPass. Please sign in and update your password.',
                          'requestId': '',
                          'timestamp': Timestamp.now(),
                          'isRead': false,
                          'recipientEmail': email,
                        });
                      } catch (_) {}

                      // Dispatch email link as well
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                      } catch (_) {}

                      // Show copy dialog
                      if (!mounted) return;
                      showDialog(
                        context: context,
                          builder: (c) => AlertDialog(
                            title: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                                const SizedBox(width: 8),
                                const Text('Password Updated'),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('New credentials provisioned for $name ($email):'),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
                                  child: SelectableText('Temporary Password: $newPass', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                                const SizedBox(height: 10),
                                Text('• Setup link also dispatched to $email.\n• User can sign in using this temporary password or the email link.', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              ],
                            ),
                            actions: [
                              TextButton.icon(
                                icon: const Icon(Icons.copy_rounded, size: 16),
                                label: const Text('Copy Password'),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: newPass));
                                  messenger.showSnackBar(const SnackBar(content: Text('Password copied to clipboard!')));
                                },
                              ),
                              ElevatedButton(onPressed: () => Navigator.pop(c), child: const Text('Done')),
                            ],
                          ),
                        );
                    }
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to update password: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Update / Send', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Edit Employee Profile & Quotas
  Future<void> _editUserProfile(Map<String, dynamic> data, String docId) async {
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final deptCtrl = TextEditingController(text: data['department'] ?? '');
    final desigCtrl = TextEditingController(text: data['designation'] ?? '');
    final mgrNameCtrl = TextEditingController(text: data['reportingManagerName'] ?? '');
    final mgrEmailCtrl = TextEditingController(text: data['reportingManagerEmail'] ?? '');
    String role = data['role'] ?? 'employee';

    final balances = Map<String, dynamic>.from(data['leaveBalances'] ?? {});
    final annualCtrl = TextEditingController(text: (balances['Annual / Paid Leave']?['remaining'] ?? 18).toString());
    final casualCtrl = TextEditingController(text: (balances['Casual Leave']?['remaining'] ?? 10).toString());
    final sickCtrl = TextEditingController(text: (balances['Sick Leave']?['remaining'] ?? 10).toString());

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 26),
                const SizedBox(width: 8),
                Expanded(child: Text('Edit User: ${data['name'] ?? ''}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: deptCtrl,
                    decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: desigCtrl,
                    decoration: const InputDecoration(labelText: 'Designation', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mgrNameCtrl,
                    decoration: const InputDecoration(labelText: 'Reporting Manager Name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mgrEmailCtrl,
                    decoration: const InputDecoration(labelText: 'Reporting Manager Email', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  Text('Role Permission:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Employee', style: TextStyle(fontSize: 12)),
                          value: 'employee',
                          groupValue: role,
                          onChanged: (v) => setModalState(() => role = v!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Admin', style: TextStyle(fontSize: 12)),
                          value: 'admin',
                          groupValue: role,
                          onChanged: (v) => setModalState(() => role = v!),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text('Adjust Leave Quotas (Remaining Days):', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: annualCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Annual', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: casualCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Casual', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: sickCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Sick', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);

                  try {
                    final annualRem = int.tryParse(annualCtrl.text) ?? 18;
                    final casualRem = int.tryParse(casualCtrl.text) ?? 10;
                    final sickRem = int.tryParse(sickCtrl.text) ?? 10;

                    final updatedBalances = {
                      'Annual / Paid Leave': {'total': 18, 'used': (18 - annualRem).clamp(0, 18), 'remaining': annualRem},
                      'Casual Leave': {'total': 10, 'used': (10 - casualRem).clamp(0, 10), 'remaining': casualRem},
                      'Sick Leave': {'total': 10, 'used': (10 - sickRem).clamp(0, 10), 'remaining': sickRem},
                    };

                    await FirebaseFirestore.instance.collection('employees').doc(docId).update({
                      'name': nameCtrl.text.trim(),
                      'department': deptCtrl.text.trim(),
                      'designation': desigCtrl.text.trim(),
                      'reportingManagerName': mgrNameCtrl.text.trim(),
                      'reportingManagerEmail': mgrEmailCtrl.text.trim(),
                      'role': role,
                      'leaveBalances': updatedBalances,
                    });

                    messenger.showSnackBar(
                      SnackBar(content: Text('✓ Profile for ${nameCtrl.text.trim()} updated successfully!'), backgroundColor: AppColors.statusApproved),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Mark or edit manual attendance for an employee
  Future<void> _markManualAttendance(String email, String name, [Map<String, dynamic>? existingData]) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedAttendanceDate);
    final docId = 'ATT-$email-$dateStr';

    TimeOfDay checkInTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay? checkOutTime;
    String status = 'Present';

    if (existingData != null) {
      if (existingData['checkInTime'] != null && existingData['checkInTime'] is Timestamp) {
        final dt = (existingData['checkInTime'] as Timestamp).toDate();
        checkInTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
      if (existingData['checkOutTime'] != null && existingData['checkOutTime'] is Timestamp) {
        final dt = (existingData['checkOutTime'] as Timestamp).toDate();
        checkOutTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      }
      status = existingData['status'] ?? 'Present';
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setModalState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.co_present_rounded, color: AppColors.primary, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Attendance: $name',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: $dateStr', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: const Color(0xFF334155))),
                  const SizedBox(height: 14),
                  // Check in picker
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE2E8F0))),
                    leading: const Icon(Icons.login_rounded, color: Colors.green),
                    title: const Text('Check-In Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(checkInTime.format(dialogCtx), style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.access_time_rounded, size: 20),
                    onTap: () async {
                      final picked = await showTimePicker(context: dialogCtx, initialTime: checkInTime);
                      if (picked != null) {
                        setModalState(() {
                          checkInTime = picked;
                          if (picked.hour > 9 || (picked.hour == 9 && picked.minute > 30)) {
                            status = 'Late';
                          } else {
                            status = 'Present';
                          }
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  // Check out picker
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE2E8F0))),
                    leading: const Icon(Icons.logout_rounded, color: Colors.orange),
                    title: const Text('Check-Out Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(checkOutTime != null ? checkOutTime!.format(dialogCtx) : 'Not Checked Out', style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (checkOutTime != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setModalState(() => checkOutTime = null),
                          ),
                        const Icon(Icons.access_time_rounded, size: 20),
                      ],
                    ),
                    onTap: () async {
                      final picked = await showTimePicker(context: dialogCtx, initialTime: checkOutTime ?? const TimeOfDay(hour: 18, minute: 0));
                      if (picked != null) {
                        setModalState(() => checkOutTime = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Text('Attendance Status:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'Present', child: Text('Present (On Time)')),
                      DropdownMenuItem(value: 'Late', child: Text('Late Arrival')),
                      DropdownMenuItem(value: 'Half Day', child: Text('Half Day')),
                      DropdownMenuItem(value: 'Excused', child: Text('Excused / Official Duty')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => status = v);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);

                  try {
                    final checkInDateTime = DateTime(
                      _selectedAttendanceDate.year,
                      _selectedAttendanceDate.month,
                      _selectedAttendanceDate.day,
                      checkInTime.hour,
                      checkInTime.minute,
                    );

                    DateTime? checkOutDateTime;
                    if (checkOutTime != null) {
                      checkOutDateTime = DateTime(
                        _selectedAttendanceDate.year,
                        _selectedAttendanceDate.month,
                        _selectedAttendanceDate.day,
                        checkOutTime!.hour,
                        checkOutTime!.minute,
                      );
                    }

                    await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
                      'id': docId,
                      'employeeEmail': email,
                      'employeeName': name,
                      'date': dateStr,
                      'status': status,
                      'checkInTime': Timestamp.fromDate(checkInDateTime),
                      'checkOutTime': checkOutDateTime != null ? Timestamp.fromDate(checkOutDateTime) : null,
                    }, SetOptions(merge: true));

                    messenger.showSnackBar(
                      SnackBar(content: Text('✓ Attendance saved for $name ($dateStr)'), backgroundColor: AppColors.statusApproved),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Failed to save attendance: $e'), backgroundColor: Colors.red),
                    );
                  }
                },
                child: const Text('Save Attendance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  // Quick Check In
  Future<void> _quickCheckInEmployee(String email, String name) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedAttendanceDate);
    final docId = 'ATT-$email-$dateStr';
    final now = DateTime.now();
    final checkInLimit = DateTime(now.year, now.month, now.day, 9, 30);
    final status = now.isAfter(checkInLimit) ? 'Late' : 'Present';

    try {
      await FirebaseFirestore.instance.collection('attendance').doc(docId).set({
        'id': docId,
        'employeeEmail': email,
        'employeeName': name,
        'date': dateStr,
        'status': status,
        'checkInTime': Timestamp.fromDate(now),
        'checkOutTime': null,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ $name marked Checked In ($status)'), backgroundColor: AppColors.statusApproved),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check in: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Quick Check Out
  Future<void> _quickCheckOutEmployee(String email, String name) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedAttendanceDate);
    final docId = 'ATT-$email-$dateStr';
    final now = DateTime.now();

    try {
      await FirebaseFirestore.instance.collection('attendance').doc(docId).update({
        'checkOutTime': Timestamp.fromDate(now),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✓ $name marked Checked Out at ${DateFormat('hh:mm a').format(now)}'), backgroundColor: AppColors.statusApproved),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to check out: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // Helper method to onboard a new user without signing out the current admin session
  Future<void> _onboardEmployee() async {
    if (!_onboardFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final dept = _deptController.text.trim();
    final desig = _designationController.text.trim();
    final mgrName = _managerNameController.text.trim();
    final mgrEmail = _managerEmailController.text.trim();
    final empId = 'EMP-${1000 + email.hashCode.abs() % 8000}';

    try {
      // 1. Write the Employee Profile Document with full enterprise leave quotas directly into Cloud Firestore
      final newEmp = EmployeeModel(
        id: empId,
        name: name,
        email: email,
        department: dept,
        designation: desig,
        reportingManagerName: mgrName,
        reportingManagerEmail: mgrEmail,
        photoUrl: '',
        role: 'employee',
        leaveBalances: EmployeeModel.defaultLeaveBalances(),
      );

      await FirebaseFirestore.instance.collection('employees').doc(email).set(newEmp.toJson());

      // 2. Automatically dispatch password setup / activation link to the employee's inbox via Firebase
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      } catch (_) {}

      // 3. Create an initial Welcome Notification for the new employee in Cloud Firestore
      final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
      try {
        await FirebaseFirestore.instance.collection('notifications').doc(notifId).set({
          'id': notifId,
          'title': 'Welcome to ERMS, $name! 🎉',
          'message': 'Your account ($email) has been provisioned. A password setup link was sent to your email. You have 18 Annual, 10 Sick, and 10 Casual leaves available.',
          'requestId': '',
          'timestamp': Timestamp.now(),
          'isRead': false,
          'recipientEmail': email,
        });
      } catch (_) {}

      if (mounted) {
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _deptController.clear();
        _designationController.clear();
        _managerNameController.clear();
        _managerEmailController.clear();

        // Show confirmation dialog with full summary
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                const SizedBox(width: 10),
                Text('Employee Onboarded!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account provisioned & welcome email dispatched:', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[700])),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryRow('Employee ID', empId),
                      _buildSummaryRow('Name', name),
                      _buildSummaryRow('Email', email),
                      _buildSummaryRow('Temp Password', password),
                      _buildSummaryRow('Department', dept),
                      _buildSummaryRow('Designation', desig),
                      _buildSummaryRow('Reporting Manager', '$mgrName ($mgrEmail)'),
                      _buildSummaryRow('Leave Quotas', 'Annual: 18, Casual: 10, Sick: 10'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '✓ Password setup / activation link sent directly to $email.\n✓ Employee can now log in, change password, and submit requests.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500),
                ),
              ],
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Copy Credentials'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(
                    text: 'ERMS Account Created\nEmployee ID: $empId\nName: $name\nEmail: $email\nTemporary Password: $password\nDepartment: $dept\nDesignation: $desig',
                  ));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Credentials copied to clipboard!')),
                  );
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _selectedTab = 5);
                },
                child: const Text('View in Directory', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Onboarding failed: ${e.toString()}'), backgroundColor: AppColors.statusRejected),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Create and assign a task
  Future<void> _assignTask() async {
    if (!_taskFormKey.currentState!.validate() || _taskAssigneeEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an employee and complete form fields'), backgroundColor: AppColors.statusRejected),
      );
      return;
    }

    setState(() => _isLoading = true);
    final taskId = 'TSK-${DateTime.now().millisecondsSinceEpoch}';
    final taskTitle = _taskTitleController.text.trim();
    final taskDesc = _taskDescController.text.trim();
    final task = TaskModel(
      id: taskId,
      title: taskTitle,
      description: taskDesc,
      assignedToEmail: _taskAssigneeEmail!,
      assignedToName: _taskAssigneeName ?? _taskAssigneeEmail!,
      assignedByEmail: 'mayurailead@gmail.com',
      dueDate: _taskDueDate,
      status: 'Pending',
      createdDate: DateTime.now(),
    );

    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).set(task.toJson());

      // Create in-app notification for the assigned employee
      final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance.collection('notifications').doc(notifId).set({
        'id': notifId,
        'title': 'New Task Assigned: $taskTitle',
        'message': 'You have been assigned a new task: "$taskTitle" due on ${DateFormat('yyyy-MM-dd').format(_taskDueDate)}.',
        'requestId': '',
        'timestamp': Timestamp.now(),
        'isRead': false,
        'recipientEmail': _taskAssigneeEmail!,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task successfully assigned and notification sent!'), backgroundColor: AppColors.statusApproved),
        );
        _taskTitleController.clear();
        _taskDescController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task assignment failed: ${e.toString()}'), backgroundColor: AppColors.statusRejected),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Approve a request with automated leave balance deduction and notifications
  Future<void> _approveRequest(Map<String, dynamic> data, String docId) async {
    setState(() => _isLoading = true);
    final empEmail = data['employeeEmail'] as String? ?? '';
    final empName = data['employeeName'] as String? ?? '';
    final reqTypeStr = data['requestType'] as String? ?? '';
    final reqData = Map<String, dynamic>.from(data['requestData'] ?? {});
    final existingHistory = List<dynamic>.from(data['approvalHistory'] ?? []);

    try {
      final isLeave = reqTypeStr.toLowerCase().contains('leave');
      int remainingBalance = 0;
      String leaveType = '';
      int days = 0;

      if (isLeave && empEmail.isNotEmpty) {
        leaveType = reqData['leaveType'] as String? ?? 'Annual / Paid Leave';
        days = (reqData['numberOfDays'] as num?)?.toInt() ?? 1;

        // Perform automated leave deduction in Firestore
        final empDocRef = FirebaseFirestore.instance.collection('employees').doc(empEmail);
        final empDoc = await empDocRef.get();

        if (empDoc.exists && empDoc.data() != null) {
          final emp = EmployeeModel.fromJson(empDoc.data()!);
          final balances = Map<String, dynamic>.from(emp.leaveBalances);

          final categoryQuota = Map<String, dynamic>.from(
            balances[leaveType] ?? {'total': 18, 'used': 0, 'remaining': 18},
          );

          final currentRemaining = (categoryQuota['remaining'] as num?)?.toInt() ?? 18;
          final currentUsed = (categoryQuota['used'] as num?)?.toInt() ?? 0;

          final newRemaining = (currentRemaining - days).clamp(0, 999);
          final newUsed = currentUsed + days;

          categoryQuota['remaining'] = newRemaining;
          categoryQuota['used'] = newUsed;
          balances[leaveType] = categoryQuota;

          await empDocRef.update({'leaveBalances': balances});
          remainingBalance = newRemaining;
        }
      }

      // Append approval step
      final newStep = {
        'title': 'Approved by Administrator',
        'actorName': 'System Administrator (mayurailead@gmail.com)',
        'actorRole': 'System Administrator',
        'timestamp': Timestamp.now(),
        'isCompleted': true,
        'isRejected': false,
        'comment': isLeave ? 'Leave approved and $days day(s) deducted from balance.' : 'Request approved by administrator.',
      };
      existingHistory.add(newStep);

      // Update Request in Firestore
      await FirebaseFirestore.instance.collection('requests').doc(docId).update({
        'status': 'approved',
        'approvalHistory': existingHistory,
      });

      // Send real-time notification to employee
      final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
      final notifMessage = isLeave
          ? 'Your $leaveType request ($docId) for $days day(s) has been approved. Your remaining $leaveType balance is $remainingBalance days.'
          : 'Your $reqTypeStr request ($docId) has been approved by the Administrator.';

      await FirebaseFirestore.instance.collection('notifications').doc(notifId).set({
        'id': notifId,
        'title': isLeave ? 'Leave Request Approved! ✅' : 'Request Approved! ✅',
        'message': notifMessage,
        'requestId': docId,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'recipientEmail': empEmail,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isLeave
                ? 'Request approved! $days day(s) automatically deducted for $empName (Remaining: $remainingBalance).'
                : 'Request $docId successfully approved!'),
            backgroundColor: AppColors.statusApproved,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e'), backgroundColor: AppColors.statusRejected),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Reject request with reason and notification
  Future<void> _rejectRequest(Map<String, dynamic> data, String docId) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Request', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please specify the reason for rejecting request $docId:', style: GoogleFonts.plusJakartaSans(fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g. Incomplete documentation, overlapping leave dates, policy restriction...',
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
            child: const Text('Reject Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final reason = reasonController.text.trim().isEmpty ? 'Rejected by Administrator' : reasonController.text.trim();

    setState(() => _isLoading = true);
    final empEmail = data['employeeEmail'] as String? ?? '';
    final reqTypeStr = data['requestType'] as String? ?? '';
    final existingHistory = List<dynamic>.from(data['approvalHistory'] ?? []);

    try {
      final newStep = {
        'title': 'Rejected by Administrator',
        'actorName': 'System Administrator (mayurailead@gmail.com)',
        'actorRole': 'System Administrator',
        'timestamp': Timestamp.now(),
        'isCompleted': false,
        'isRejected': true,
        'comment': reason,
      };
      existingHistory.add(newStep);

      await FirebaseFirestore.instance.collection('requests').doc(docId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'approvalHistory': existingHistory,
      });

      final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
      await FirebaseFirestore.instance.collection('notifications').doc(notifId).set({
        'id': notifId,
        'title': 'Request Rejected ❌',
        'message': 'Your $reqTypeStr request ($docId) was rejected. Reason: $reason',
        'requestId': docId,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'recipientEmail': empEmail,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $docId has been rejected.'), backgroundColor: AppColors.statusRejected),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejection failed: $e'), backgroundColor: AppColors.statusRejected),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              '$label:',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    final sidebarContent = Container(
      width: 270,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Brand Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'ERMS Admin Portal',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          // Sidebar Options
          _buildSidebarItem(0, Icons.dashboard_outlined, 'Overview'),
          _buildSidebarItem(5, Icons.supervised_user_circle_outlined, 'User Management'),
          _buildSidebarItem(1, Icons.person_add_alt_1_outlined, '+ Create User'),
          _buildSidebarItem(2, Icons.assignment_turned_in_outlined, 'Leave & Requests'),
          _buildSidebarItem(4, Icons.playlist_add_check_rounded, 'Task Management'),
          _buildSidebarItem(3, Icons.co_present_rounded, 'Attendance Logs'),
          _buildSidebarItem(6, Icons.campaign_rounded, 'Broadcast Notices'),
          _buildSidebarItem(7, Icons.receipt_long_rounded, 'Audit Trail & Logs'),
          const Spacer(),
          // Switch to Employee Mode
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              leading: const Icon(Icons.badge_outlined, color: Colors.lightBlueAccent),
              title: Text(
                'Employee Portal',
                style: GoogleFonts.plusJakartaSans(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              onTap: () {
                context.go('/');
              },
            ),
          ),
          // Logout button
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text(
              'Logout',
              style: GoogleFonts.plusJakartaSans(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            ['Overview', '+ Create User', 'Requests', 'Attendance Logs', 'Task Management', 'User Management', 'Broadcast Notices', 'Audit Trail'][_selectedTab],
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          backgroundColor: const Color(0xFF0F172A),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.badge_outlined),
              tooltip: 'Switch to Employee View',
              onPressed: () => context.go('/'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildNavPill(0, Icons.dashboard_rounded, 'Overview'),
                  _buildNavPill(5, Icons.manage_accounts_rounded, 'User Management'),
                  _buildNavPill(1, Icons.person_add_rounded, '+ Create User'),
                  _buildNavPill(2, Icons.approval_rounded, 'Requests'),
                  _buildNavPill(3, Icons.access_time_filled_rounded, 'Attendance'),
                  _buildNavPill(4, Icons.task_alt_rounded, 'Tasks'),
                  _buildNavPill(6, Icons.campaign_rounded, 'Notices'),
                  _buildNavPill(7, Icons.receipt_long_rounded, 'Audit Trail'),
                ],
              ),
            ),
          ),
        ),
        drawer: Drawer(child: sidebarContent),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildSelectedView(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          sidebarContent,
          // Main content panel
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: _buildSelectedView(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavPill(int index, IconData icon, String title) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: isSelected ? Colors.white : Colors.grey[300]),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? Colors.white : Colors.grey[300],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title) {
    final isSelected = _selectedTab == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.grey[400]),
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          setState(() => _selectedTab = index);
        },
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedTab) {
      case 0:
        return _buildOverviewTab();
      case 1:
        return _buildOnboardingTab();
      case 2:
        return _buildRequestsTab();
      case 3:
        return _buildAttendanceTab();
      case 4:
        return _buildTasksTab();
      case 5:
        return _buildDirectoryTab();
      case 6:
        return _buildAnnouncementsTab();
      case 7:
        return _buildAuditLogsTab();
      default:
        return const SizedBox();
    }
  }

  // --- Views ---

  Widget _buildOverviewTab() {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('employees').snapshots(),
      builder: (context, empSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('requests').snapshots(),
          builder: (context, reqSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
              builder: (context, taskSnap) {
                final empDocs = empSnap.data?.docs ?? [];
                final totalEmployees = empDocs.length;
                final activeLogins = empDocs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final isActive = data['isActive'] ?? (data['status'] != 'deactivated');
                  return isActive == true;
                }).length;
                final deactivatedLogins = totalEmployees - activeLogins;

                final reqDocs = reqSnap.data?.docs ?? [];
                final pendingLeaves = reqDocs.where((doc) {
                  final s = (doc['status'] ?? '').toString().toLowerCase();
                  return s.contains('pending');
                }).length;

                final totalTasks = taskSnap.data?.docs.length ?? 0;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Admin Management Portal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 22 : 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Automated HR, Employee Onboarding & Leave Quota Management',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: isMobile ? 12 : 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Metrics Cards (Responsive Grid/Wrap)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildMetricCard(
                            'Total Staff',
                            totalEmployees.toString(),
                            Icons.people_alt_rounded,
                            AppColors.primary,
                            width: isMobile ? (MediaQuery.of(context).size.width - 44) / 2 : 220,
                          ),
                          _buildMetricCard(
                            'Active Logins',
                            activeLogins.toString(),
                            Icons.verified_user_rounded,
                            Colors.teal,
                            width: isMobile ? (MediaQuery.of(context).size.width - 44) / 2 : 220,
                          ),
                          _buildMetricCard(
                            'Pending Leaves',
                            pendingLeaves.toString(),
                            Icons.pending_actions_rounded,
                            Colors.orangeAccent,
                            width: isMobile ? (MediaQuery.of(context).size.width - 44) / 2 : 220,
                          ),
                          _buildMetricCard(
                            'Assigned Tasks',
                            totalTasks.toString(),
                            Icons.task_alt_rounded,
                            Colors.green,
                            width: isMobile ? (MediaQuery.of(context).size.width - 44) / 2 : 220,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Quick Action Center
                      Text(
                        'Quick Administrative Actions',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildQuickActionTile(
                            title: '+ Onboard Employee',
                            subtitle: 'Create login & auto-send welcome email',
                            icon: Icons.person_add_rounded,
                            color: AppColors.primary,
                            onTap: () => setState(() => _selectedTab = 1),
                            width: isMobile ? double.infinity : 280,
                          ),
                          _buildQuickActionTile(
                            title: 'Employee Directory & Logins',
                            subtitle: 'Activate/deactivate app access ($deactivatedLogins inactive)',
                            icon: Icons.manage_accounts_rounded,
                            color: Colors.teal,
                            onTap: () => setState(() => _selectedTab = 5),
                            width: isMobile ? double.infinity : 280,
                          ),
                          _buildQuickActionTile(
                            title: 'Review Leave Requests',
                            subtitle: '$pendingLeaves pending automated deduction',
                            icon: Icons.approval_rounded,
                            color: Colors.orange,
                            onTap: () => setState(() => _selectedTab = 2),
                            width: isMobile ? double.infinity : 280,
                          ),
                          _buildQuickActionTile(
                            title: 'Assign Employee Tasks',
                            subtitle: 'Delegate tasks and track completion',
                            icon: Icons.add_task_rounded,
                            color: Colors.indigo,
                            onTap: () => setState(() => _selectedTab = 4),
                            width: isMobile ? double.infinity : 280,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Recent Requests Preview
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Pending Requests',
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _selectedTab = 2),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (pendingLeaves == 0)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Center(
                            child: Text(
                              '✓ All leave requests are up to date!',
                              style: GoogleFonts.plusJakartaSans(color: Colors.green, fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                      else
                        ...reqDocs
                            .where((doc) {
                              final s = (doc['status'] ?? '').toString().toLowerCase();
                              return s.contains('pending');
                            })
                            .take(3)
                            .map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final id = data['requestId'] ?? doc.id;
                              final empName = data['employeeName'] ?? '';
                              final empEmail = data['employeeEmail'] ?? '';
                              final reqData = Map<String, dynamic>.from(data['requestData'] ?? {});
                              final leaveType = reqData['leaveType'] ?? data['requestType'] ?? 'Leave';
                              final days = reqData['numberOfDays'] ?? 1;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                child: ListTile(
                                  title: Text('$empName - $leaveType ($days days)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text(empEmail, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    onPressed: () => _approveRequest(data, id),
                                    child: const Text('Approve & Deduct', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                ),
                              );
                            }),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String count, IconData icon, Color color, {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double width,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]), maxLines: 2),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingTab() {
    return SingleChildScrollView(
      child: Form(
        key: _onboardFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Onboard New Employee Profile',
              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              'Provisions Firebase Auth account, leave balances in Firestore, and sends password setup email.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            Container(
              constraints: const BoxConstraints(maxWidth: 650),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    label: 'Full Name',
                    hint: 'e.g. John Doe',
                    controller: _nameController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  CustomTextField(
                    label: 'Work Email Address',
                    hint: 'employee@company.com',
                    controller: _emailController,
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty || !val.contains('@') || val.startsWith('@') || val.endsWith('@')) {
                        return 'Provide a valid work email (e.g. name@company.com)';
                      }
                      return null;
                    },
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: CustomTextField(
                          label: 'Initial Temporary Password',
                          hint: 'Password123!',
                          obscureText: true,
                          controller: _passwordController,
                          validator: (v) => (v == null || v.length < 6) ? 'Must be at least 6 characters' : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Generate', style: TextStyle(fontSize: 12)),
                          onPressed: () {
                            final rand = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
                            _passwordController.text = 'Emp@$rand';
                          },
                        ),
                      ),
                    ],
                  ),
                  CustomTextField(
                    label: 'Department',
                    hint: 'e.g. Engineering / HR / Operations',
                    controller: _deptController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Department is required' : null,
                  ),
                  CustomTextField(
                    label: 'Designation',
                    hint: 'e.g. Software Engineer / Manager',
                    controller: _designationController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Designation is required' : null,
                  ),
                  CustomTextField(
                    label: 'Reporting Manager Name',
                    hint: 'e.g. Sarah Jenkins',
                    controller: _managerNameController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Manager name is required' : null,
                  ),
                  CustomTextField(
                    label: 'Reporting Manager Email',
                    hint: 'manager@company.com',
                    controller: _managerEmailController,
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty || !val.contains('@') || val.startsWith('@') || val.endsWith('@')) {
                        return 'Provide a valid email (e.g. manager@company.com)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Automated Leave Quotas: 18 Annual, 10 Casual, 10 Sick days will be assigned automatically.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.blue[900], fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'Onboard Employee & Send Welcome Email',
                    isLoading: _isLoading,
                    onPressed: _onboardEmployee,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leave & Request Approvals',
          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 4),
        Text(
          'Approving a request automatically deducts leave days from the employee\'s quota in Firestore.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('requests').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Text('No requests found', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final id = data['requestId'] ?? docs[index].id;
                  final empName = data['employeeName'] ?? '';
                  final empEmail = data['employeeEmail'] ?? '';
                  final type = data['requestType'] ?? '';
                  final status = (data['status'] ?? '').toString();
                  
                  String date = '';
                  if (data['submittedAt'] != null) {
                    if (data['submittedAt'] is Timestamp) {
                      date = DateFormat('yyyy-MM-dd').format((data['submittedAt'] as Timestamp).toDate());
                    } else if (data['submittedAt'] is DateTime) {
                      date = DateFormat('yyyy-MM-dd').format(data['submittedAt'] as DateTime);
                    } else {
                      final parsed = DateTime.tryParse(data['submittedAt'].toString());
                      if (parsed != null) {
                        date = DateFormat('yyyy-MM-dd').format(parsed);
                      }
                    }
                  }

                  final isPending = status.toLowerCase().contains('pending');
                  final reqData = Map<String, dynamic>.from(data['requestData'] ?? {});
                  final reason = reqData['reason'] as String? ?? '';
                  final leaveCategory = reqData['leaveType'] as String? ?? type;
                  final days = reqData['numberOfDays'];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '$empName ($empEmail)',
                                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPending
                                      ? Colors.orangeAccent.withValues(alpha: 0.1)
                                      : (status.toLowerCase() == 'approved'
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.red.withValues(alpha: 0.1)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isPending
                                        ? Colors.orange
                                        : (status.toLowerCase() == 'approved' ? Colors.green : Colors.red),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Category: $leaveCategory ${days != null ? "($days Days)" : ""}  •  ID: $id  •  Submitted: $date',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                          if (reason.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('Reason: $reason', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[800])),
                          ],
                          if (isPending) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                                  label: const Text('Approve & Deduct', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () => _approveRequest(data, id),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white),
                                  label: const Text('Reject', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  onPressed: () => _rejectRequest(data, id),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab() {
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedAttendanceDate);
    final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == selectedDateStr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Attendance Management',
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Live check-in monitoring, daily employee attendance, and historical records.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Date Picker Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded, size: 22),
                tooltip: 'Previous Day',
                onPressed: () {
                  setState(() {
                    _selectedAttendanceDate = _selectedAttendanceDate.subtract(const Duration(days: 1));
                  });
                },
              ),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedAttendanceDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() => _selectedAttendanceDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          isToday ? 'Today, ${DateFormat('dd MMM yyyy').format(_selectedAttendanceDate)}' : DateFormat('EEE, dd MMM yyyy').format(_selectedAttendanceDate),
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded, size: 22),
                tooltip: 'Next Day',
                onPressed: () {
                  setState(() {
                    _selectedAttendanceDate = _selectedAttendanceDate.add(const Duration(days: 1));
                  });
                },
              ),
              if (!isToday) ...[
                const SizedBox(width: 4),
                TextButton(
                  onPressed: () => setState(() => _selectedAttendanceDate = DateTime.now()),
                  child: const Text('Today', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Sub View Switcher Tabs (Live Status vs Full Log)
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _attendanceTabMode = 0),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _attendanceTabMode == 0 ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _attendanceTabMode == 0 ? AppColors.primary : const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Text(
                      '👥 All Employees ($selectedDateStr)',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _attendanceTabMode == 0 ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _attendanceTabMode = 1),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _attendanceTabMode == 1 ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _attendanceTabMode == 1 ? AppColors.primary : const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Text(
                      '📜 Historical Attendance Logs',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _attendanceTabMode == 1 ? Colors.white : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Bar
        TextField(
          controller: _searchAttendanceController,
          decoration: InputDecoration(
            hintText: 'Search employee name, email, or status...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
            suffixIcon: _attendanceSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchAttendanceController.clear();
                      setState(() => _attendanceSearchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
          onChanged: (v) => setState(() => _attendanceSearchQuery = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 12),

        // Main Attendance Body
        Expanded(
          child: _attendanceTabMode == 0
              ? _buildDailyAllEmployeesAttendanceView(selectedDateStr)
              : _buildHistoricalAttendanceLogView(),
        ),
      ],
    );
  }

  Widget _buildDailyAllEmployeesAttendanceView(String dateStr) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('employees').snapshots(),
      builder: (context, empSnapshot) {
        if (empSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final empDocs = empSnapshot.data?.docs ?? [];
        if (empDocs.isEmpty) {
          return Center(
            child: Text('No employees found in directory.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          );
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('attendance').where('date', isEqualTo: dateStr).snapshots(),
          builder: (context, attSnapshot) {
            if (attSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final attDocs = attSnapshot.data?.docs ?? [];
            final Map<String, Map<String, dynamic>> attendanceMap = {};
            for (var doc in attDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final email = data['employeeEmail'] as String? ?? '';
              if (email.isNotEmpty) {
                attendanceMap[email.toLowerCase()] = data;
              }
            }

            int presentCount = 0;
            int lateCount = 0;
            int notCheckedInCount = 0;

            for (var doc in empDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final email = (data['email'] ?? doc.id).toString().toLowerCase();
              final att = attendanceMap[email];
              if (att != null) {
                if (att['status'] == 'Late') {
                  lateCount++;
                } else {
                  presentCount++;
                }
              } else {
                notCheckedInCount++;
              }
            }

            // Filter employees by query and filter chip
            final filteredEmployees = empDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              final email = (data['email'] ?? doc.id).toString().toLowerCase();
              final dept = (data['department'] ?? '').toString().toLowerCase();
              final att = attendanceMap[email];

              final matchesQuery = _attendanceSearchQuery.isEmpty ||
                  name.contains(_attendanceSearchQuery) ||
                  email.contains(_attendanceSearchQuery) ||
                  dept.contains(_attendanceSearchQuery);

              if (!matchesQuery) return false;

              if (_attendanceFilterStatus == 'Present') {
                return att != null && att['status'] != 'Late';
              } else if (_attendanceFilterStatus == 'Late') {
                return att != null && att['status'] == 'Late';
              } else if (_attendanceFilterStatus == 'Not Checked In') {
                return att == null;
              }
              return true;
            }).toList();

            return Column(
              children: [
                // Real-time Stat Cards
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAttendanceStatCard('Total Users', '${empDocs.length}', const Color(0xFF0F172A), () => setState(() => _attendanceFilterStatus = 'All'), _attendanceFilterStatus == 'All'),
                      const SizedBox(width: 8),
                      _buildAttendanceStatCard('Present', '$presentCount', Colors.green, () => setState(() => _attendanceFilterStatus = 'Present'), _attendanceFilterStatus == 'Present'),
                      const SizedBox(width: 8),
                      _buildAttendanceStatCard('Late', '$lateCount', Colors.orange, () => setState(() => _attendanceFilterStatus = 'Late'), _attendanceFilterStatus == 'Late'),
                      const SizedBox(width: 8),
                      _buildAttendanceStatCard('Not Checked In', '$notCheckedInCount', Colors.red, () => setState(() => _attendanceFilterStatus = 'Not Checked In'), _attendanceFilterStatus == 'Not Checked In'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Employee Cards List
                Expanded(
                  child: filteredEmployees.isEmpty
                      ? Center(child: Text('No employees match filter "$_attendanceFilterStatus"', style: GoogleFonts.plusJakartaSans(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: filteredEmployees.length,
                          itemBuilder: (context, index) {
                            final doc = filteredEmployees[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final name = data['name'] ?? 'Employee';
                            final email = (data['email'] ?? doc.id).toString();
                            final dept = data['department'] ?? 'General';
                            final desig = data['designation'] ?? 'Staff';
                            final att = attendanceMap[email.toLowerCase()];

                            final bool hasCheckedIn = att != null && att['checkInTime'] != null;
                            final String checkInStr = hasCheckedIn
                                ? DateFormat('hh:mm a').format((att['checkInTime'] as Timestamp).toDate())
                                : 'Not Checked In';
                            final bool hasCheckedOut = att != null && att['checkOutTime'] != null;
                            final String checkOutStr = hasCheckedOut
                                ? DateFormat('hh:mm a').format((att['checkOutTime'] as Timestamp).toDate())
                                : (hasCheckedIn ? 'In Progress (Working)' : '—');
                            final String statusStr = att != null ? (att['status'] ?? 'Present') : 'Not Checked In';

                            Color statusColor = Colors.red;
                            if (statusStr == 'Present') statusColor = Colors.green;
                            if (statusStr == 'Late') statusColor = Colors.orange;
                            if (hasCheckedOut) statusColor = Colors.blue;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: hasCheckedIn ? const Color(0xFFE2E8F0) : Colors.red.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              color: hasCheckedIn ? Colors.white : const Color(0xFFFFFBFB),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row 1: Avatar, Name, Status Badge
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 20,
                                          backgroundColor: hasCheckedIn ? AppColors.primary : Colors.grey[400],
                                          child: Text(
                                            name.isNotEmpty ? name[0].toUpperCase() : 'E',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
                                              Text('$desig • $dept', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600])),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            hasCheckedOut ? 'Checked Out' : statusStr,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: statusColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                    const SizedBox(height: 10),

                                    // Row 2: Check-In & Check-Out Timestamps
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.login_rounded, size: 16, color: hasCheckedIn ? Colors.green : Colors.grey),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Check In', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                                      Text(checkInStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: hasCheckedIn ? const Color(0xFF0F172A) : Colors.grey)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.logout_rounded, size: 16, color: hasCheckedOut ? Colors.orange : Colors.grey),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text('Check Out', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                                                      Text(checkOutStr, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: hasCheckedOut ? const Color(0xFF0F172A) : Colors.grey)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Row 3: Admin Action Controls
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 6,
                                      children: [
                                        OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          icon: const Icon(Icons.edit_calendar_rounded, size: 14),
                                          label: Text(hasCheckedIn ? 'Edit Attendance' : 'Mark Attendance', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                          onPressed: () => _markManualAttendance(email, name, att),
                                        ),
                                        if (!hasCheckedIn)
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              elevation: 0,
                                            ),
                                            icon: const Icon(Icons.check_circle_rounded, size: 14),
                                            label: const Text('Quick Check-In', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            onPressed: () => _quickCheckInEmployee(email, name),
                                          )
                                        else if (!hasCheckedOut)
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.orange,
                                              foregroundColor: Colors.white,
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              elevation: 0,
                                            ),
                                            icon: const Icon(Icons.logout_rounded, size: 14),
                                            label: const Text('Quick Check-Out', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                            onPressed: () => _quickCheckOutEmployee(email, name),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceStatCard(String title, String count, Color color, VoidCallback onTap, bool isSelected) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text('$title: ', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500)),
            Text(count, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoricalAttendanceLogView() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        if (allDocs.isEmpty) {
          return Center(
            child: Text('No historical attendance records found.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          );
        }

        // Sort by checkInTime descending
        final sortedDocs = List<QueryDocumentSnapshot>.from(allDocs);
        sortedDocs.sort((a, b) {
          final dataA = a.data() as Map<String, dynamic>;
          final dataB = b.data() as Map<String, dynamic>;
          final timeA = (dataA['checkInTime'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final timeB = (dataB['checkInTime'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return timeB.compareTo(timeA);
        });

        // Filter by query
        final filteredDocs = sortedDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['employeeName'] ?? '').toString().toLowerCase();
          final email = (data['employeeEmail'] ?? '').toString().toLowerCase();
          final date = (data['date'] ?? '').toString().toLowerCase();
          final status = (data['status'] ?? '').toString().toLowerCase();

          if (_attendanceSearchQuery.isEmpty) return true;
          return name.contains(_attendanceSearchQuery) ||
              email.contains(_attendanceSearchQuery) ||
              date.contains(_attendanceSearchQuery) ||
              status.contains(_attendanceSearchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(
            child: Text('No logs match "$_attendanceSearchQuery"', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          );
        }

        return ListView.builder(
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['employeeName'] ?? '';
            final email = data['employeeEmail'] ?? '';
            final date = data['date'] ?? '';
            final status = data['status'] ?? 'Present';

            final checkIn = data['checkInTime'] != null
                ? DateFormat('hh:mm a').format((data['checkInTime'] as Timestamp).toDate())
                : 'N/A';
            final checkOut = data['checkOutTime'] != null
                ? DateFormat('hh:mm a').format((data['checkOutTime'] as Timestamp).toDate())
                : 'Not Checked Out';

            Color statusColor = status == 'Late' ? Colors.orange : Colors.green;
            if (data['checkOutTime'] != null) statusColor = Colors.blue;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary,
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'E', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('$email • $date', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Text('In: $checkIn  |  Out: $checkOut', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF334155))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTasksTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;

        final formWidget = Container(
          width: isNarrow ? double.infinity : 380,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Form(
            key: _taskFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Assign a New Task', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 14),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('employees').snapshots(),
                  builder: (context, snapshot) {
                    final list = snapshot.data?.docs ?? [];
                    return DropdownButtonFormField<String>(
                      initialValue: _taskAssigneeEmail,
                      hint: const Text('Select Assignee'),
                      isExpanded: true,
                      items: list.map((doc) {
                        final email = doc['email'] as String? ?? '';
                        final name = doc['name'] as String? ?? email;
                        return DropdownMenuItem(value: email, child: Text(name));
                      }).toList(),
                      onChanged: (email) {
                        if (email != null) {
                          final doc = list.firstWhere((element) => element['email'] == email);
                          setState(() {
                            _taskAssigneeEmail = email;
                            _taskAssigneeName = doc['name'];
                          });
                        }
                      },
                      validator: (v) => v == null ? 'Assignee required' : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Task Title',
                  hint: 'Write task title',
                  controller: _taskTitleController,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                CustomTextField(
                  label: 'Task Description',
                  hint: 'What needs to be done?',
                  controller: _taskDescController,
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: 'Assign Task & Notify',
                  isLoading: _isLoading,
                  onPressed: _assignTask,
                ),
              ],
            ),
          ),
        );

        final taskListWidget = StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
          builder: (context, snapshot) {
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(child: Text('No tasks assigned yet.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)));
            }

            return ListView.builder(
              shrinkWrap: isNarrow,
              physics: isNarrow ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final title = data['title'] ?? '';
                final desc = data['description'] ?? '';
                final assignee = data['assignedToName'] ?? '';
                final status = data['status'] ?? '';
                String due = '';
                if (data['dueDate'] != null) {
                  if (data['dueDate'] is Timestamp) {
                    due = DateFormat('yyyy-MM-dd').format((data['dueDate'] as Timestamp).toDate());
                  } else if (data['dueDate'] is DateTime) {
                    due = DateFormat('yyyy-MM-dd').format(data['dueDate'] as DateTime);
                  }
                }

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (status == 'Completed' ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: status == 'Completed' ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[700])),
                        const SizedBox(height: 8),
                        Text('Assigned To: $assignee  •  Due: $due', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );

        if (isNarrow) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Task Management', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                formWidget,
                const SizedBox(height: 24),
                Text('Existing Assigned Tasks', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                taskListWidget,
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Task Management & Assignments', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  formWidget,
                  const SizedBox(width: 24),
                  Expanded(child: taskListWidget),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDirectoryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header with Add New Employee Action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Management Center',
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Create users, delete accounts, change passwords, and manage app access permissions.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18, color: Colors.white),
              label: const Text('+ Create User', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => setState(() => _selectedTab = 1),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Search Bar
        TextField(
          controller: _searchDirectoryController,
          decoration: InputDecoration(
            hintText: 'Search by name, email, department, or status...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
            suffixIcon: _searchDirectoryQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchDirectoryController.clear();
                      setState(() => _searchDirectoryQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          onChanged: (val) => setState(() => _searchDirectoryQuery = val.trim().toLowerCase()),
        ),
        const SizedBox(height: 16),

        // Employee Cards List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('employees').snapshots(),
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDocs = snapshot.data?.docs ?? [];
              if (allDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_off_rounded, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('No employees onboarded yet.', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                        label: const Text('Onboard First Employee', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        onPressed: () => setState(() => _selectedTab = 1),
                      ),
                    ],
                  ),
                );
              }

              // Filter by query
              final docs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                final dept = (data['department'] ?? '').toString().toLowerCase();
                final status = (data['status'] ?? '').toString().toLowerCase();
                if (_searchDirectoryQuery.isEmpty) return true;
                return name.contains(_searchDirectoryQuery) ||
                    email.contains(_searchDirectoryQuery) ||
                    dept.contains(_searchDirectoryQuery) ||
                    status.contains(_searchDirectoryQuery);
              }).toList();

              if (docs.isEmpty) {
                return Center(
                  child: Text('No employees match "$_searchDirectoryQuery"', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['name'] ?? '';
                  final email = data['email'] ?? doc.id;
                  final dept = data['department'] ?? 'General';
                  final desig = data['designation'] ?? 'Staff';
                  final mgr = data['reportingManagerName'] ?? 'N/A';
                  final role = data['role'] ?? 'employee';
                  final isAdmin = role == 'admin' || email == 'mayurailead@gmail.com';

                  final rawIsActive = data['isActive'];
                  final bool isActive = rawIsActive is bool ? rawIsActive : (data['status'] != 'deactivated');

                  final balances = Map<String, dynamic>.from(data['leaveBalances'] ?? {});
                  final annualRemaining = balances['Annual / Paid Leave']?['remaining'] ?? 18;
                  final casualRemaining = balances['Casual Leave']?['remaining'] ?? 10;
                  final sickRemaining = balances['Sick Leave']?['remaining'] ?? 10;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isActive ? const Color(0xFFE2E8F0) : Colors.red.withValues(alpha: 0.3),
                        width: isActive ? 1 : 1.5,
                      ),
                    ),
                    color: isActive ? Colors.white : Colors.red.withValues(alpha: 0.02),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Avatar, Name, Role & Status Badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: isAdmin ? Colors.purple : AppColors.primary,
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'E',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            name,
                                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isAdmin) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                                            child: const Text('Admin', style: TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('$desig • $dept', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isActive ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      size: 12,
                                      color: isActive ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isActive ? 'Active Login' : 'Deactivated',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? Colors.green : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 10),

                          // Contact & Manager Details
                          Wrap(
                            spacing: 16,
                            runSpacing: 6,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(email, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[700])),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.supervisor_account_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('Manager: $mgr', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[700])),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Leave Quotas Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Remaining Leaves: Annual: $annualRemaining days  •  Casual: $casualRemaining days  •  Sick: $sickRemaining days',
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF334155), fontWeight: FontWeight.w500),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Action Buttons
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Change Password Button
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 0,
                                ),
                                icon: const Icon(Icons.key_rounded, size: 16),
                                label: const Text('Change Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _changeUserPassword(email, name),
                              ),

                              // Edit Profile Button
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF334155),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.edit_note_rounded, size: 16),
                                label: const Text('Edit Profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                onPressed: () => _editUserProfile(data, doc.id),
                              ),

                              // Toggle App Login (Activate / Deactivate)
                              if (!isAdmin) ...[
                                if (isActive)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red[700],
                                      side: BorderSide(color: Colors.red.withValues(alpha: 0.4)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.block_rounded, size: 16),
                                    label: const Text('Deactivate Login', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    onPressed: () => _toggleEmployeeStatus(email, name, isActive),
                                  )
                                else
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                    label: const Text('Activate Login', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    onPressed: () => _toggleEmployeeStatus(email, name, isActive),
                                  ),
                              ],

                              // Delete Employee
                              if (!isAdmin)
                                IconButton(
                                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 22),
                                  tooltip: 'Delete User Profile',
                                  onPressed: () => _deleteEmployee(doc.id, name, email),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Broadcast Announcements & Notices', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text('Publish company-wide announcements. Automatically notifies all employees in real-time.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 20),

          // Broadcast Creator Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create New Organization Notice', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Announcement Title',
                  hint: 'e.g. Office Holiday Notice / Townhall Meeting',
                  controller: _announcementTitleCtrl,
                ),
                CustomTextField(
                  label: 'Broadcast Message',
                  hint: 'Provide full notice details for all staff...',
                  controller: _announcementMsgCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Text('Priority Level:', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _announcementPriority,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Normal', child: Text('Normal (General Information)')),
                    DropdownMenuItem(value: 'Important', child: Text('Important (High Priority)')),
                    DropdownMenuItem(value: 'Urgent', child: Text('🚨 Urgent (Action Required)')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _announcementPriority = v);
                  },
                ),
                const SizedBox(height: 18),
                CustomButton(
                  text: 'Broadcast Notice & Notify All Employees',
                  isLoading: _isLoading,
                  onPressed: () async {
                    final title = _announcementTitleCtrl.text.trim();
                    final msg = _announcementMsgCtrl.text.trim();
                    if (title.isEmpty || msg.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please provide both title and message'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    setState(() => _isLoading = true);
                    try {
                      final notifId = 'ANN-${DateTime.now().millisecondsSinceEpoch}';
                      await FirebaseFirestore.instance.collection('announcements').doc(notifId).set({
                        'id': notifId,
                        'title': title,
                        'message': msg,
                        'priority': _announcementPriority,
                        'createdBy': 'System Administrator',
                        'createdAt': Timestamp.now(),
                      });

                      // Broadcast in-app notification
                      final sysNotifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
                      await FirebaseFirestore.instance.collection('notifications').doc(sysNotifId).set({
                        'id': sysNotifId,
                        'title': '📢 $title',
                        'message': msg,
                        'requestId': notifId,
                        'timestamp': Timestamp.now(),
                        'isRead': false,
                        'recipientEmail': 'all',
                      });

                      // Audit log
                      final audId = 'AUD-${DateTime.now().millisecondsSinceEpoch}';
                      await FirebaseFirestore.instance.collection('audit_logs').doc(audId).set({
                        'id': audId,
                        'action': 'ANNOUNCEMENT_BROADCAST',
                        'performedBy': 'mayurailead@gmail.com',
                        'targetEmail': 'all',
                        'details': 'Title: $title ($notifId)',
                        'timestamp': Timestamp.now(),
                      });

                      _announcementTitleCtrl.clear();
                      _announcementMsgCtrl.clear();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✓ Announcement broadcast to all employees!'), backgroundColor: AppColors.statusApproved),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to broadcast: $e'), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isLoading = false);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Active Broadcast Notices List
          Text('Active Broadcast Notices', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('announcements').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('No active broadcast notices.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = data['title'] ?? '';
                  final msg = data['message'] ?? '';
                  final priority = data['priority'] ?? 'Normal';
                  final createdAt = data['createdAt'] != null
                      ? DateFormat('yyyy-MM-dd hh:mm a').format((data['createdAt'] as Timestamp).toDate())
                      : '';

                  Color pColor = Colors.blue;
                  if (priority == 'Important') pColor = Colors.orange;
                  if (priority == 'Urgent') pColor = Colors.red;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: pColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: Icon(Icons.campaign_rounded, color: pColor, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: pColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                      child: Text(priority, style: TextStyle(color: pColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(msg, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                                const SizedBox(height: 8),
                                Text('Published: $createdAt', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            tooltip: 'Delete Announcement',
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('announcements').doc(doc.id).delete();
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('System Compliance & Audit Trail', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text('Immutable log of administrative operations, leave approvals, and user status changes.', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 16),

        // Search Bar
        TextField(
          controller: _auditSearchCtrl,
          decoration: InputDecoration(
            hintText: 'Search audit logs by action, actor, or target email...',
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
            suffixIcon: _auditSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _auditSearchCtrl.clear();
                      setState(() => _auditSearchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
          onChanged: (v) => setState(() => _auditSearchQuery = v.trim().toLowerCase()),
        ),
        const SizedBox(height: 16),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('audit_logs').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allDocs = snapshot.data?.docs ?? [];
              if (allDocs.isEmpty) {
                return Center(
                  child: Text('No audit events logged yet.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                );
              }

              final sortedDocs = List<QueryDocumentSnapshot>.from(allDocs);
              sortedDocs.sort((a, b) {
                final dataA = a.data() as Map<String, dynamic>;
                final dataB = b.data() as Map<String, dynamic>;
                final timeA = (dataA['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
                final timeB = (dataB['timestamp'] as Timestamp?)?.toDate() ?? DateTime(2000);
                return timeB.compareTo(timeA);
              });

              final filtered = sortedDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final act = (data['action'] ?? '').toString().toLowerCase();
                final by = (data['performedBy'] ?? '').toString().toLowerCase();
                final target = (data['targetEmail'] ?? '').toString().toLowerCase();
                final details = (data['details'] ?? '').toString().toLowerCase();

                if (_auditSearchQuery.isEmpty) return true;
                return act.contains(_auditSearchQuery) ||
                    by.contains(_auditSearchQuery) ||
                    target.contains(_auditSearchQuery) ||
                    details.contains(_auditSearchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return Center(child: Text('No audit logs match "$_auditSearchQuery"', style: GoogleFonts.plusJakartaSans(color: Colors.grey)));
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final doc = filtered[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final action = data['action'] ?? 'SYSTEM_EVENT';
                  final by = data['performedBy'] ?? 'Admin';
                  final target = data['targetEmail'] ?? '';
                  final details = data['details'] ?? '';
                  final timeStr = data['timestamp'] != null
                      ? DateFormat('yyyy-MM-dd hh:mm a').format((data['timestamp'] as Timestamp).toDate())
                      : '';

                  Color actionColor = AppColors.primary;
                  if (action.toString().contains('APPROVED')) actionColor = Colors.green;
                  if (action.toString().contains('REJECTED') || action.toString().contains('DELETED')) actionColor = Colors.red;
                  if (action.toString().contains('ONBOARDED')) actionColor = Colors.purple;
                  if (action.toString().contains('ATTENDANCE')) actionColor = Colors.teal;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: Color(0xFFE2E8F0))),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: actionColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              action,
                              style: TextStyle(color: actionColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(details, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 2),
                                Text('By: $by  →  Target: $target', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                const SizedBox(height: 2),
                                Text(timeStr, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
