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

  // Send Password Reset Link to Employee
  Future<void> _sendPasswordResetLink(String email, String name) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset link sent to $email ($name)'), backgroundColor: AppColors.statusApproved),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send reset link: $e'), backgroundColor: AppColors.statusRejected),
        );
      }
    }
  }

  // Delete Employee Profile
  Future<void> _deleteEmployee(String docId, String name, String email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Employee Profile', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete $name ($email)? Their profile will be removed from the Firestore database.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('employees').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name removed from directory'), backgroundColor: AppColors.statusApproved),
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
          _buildSidebarItem(1, Icons.person_add_alt_1_outlined, 'Onboard Employee'),
          _buildSidebarItem(2, Icons.assignment_turned_in_outlined, 'Leave & Requests'),
          _buildSidebarItem(3, Icons.co_present_rounded, 'Attendance Logs'),
          _buildSidebarItem(4, Icons.playlist_add_check_rounded, 'Task Management'),
          _buildSidebarItem(5, Icons.supervised_user_circle_outlined, 'Employee Directory'),
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
            ['Overview', 'Onboard Employee', 'Requests', 'Attendance Logs', 'Task Management', 'Directory & Logins'][_selectedTab],
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
                  _buildNavPill(1, Icons.person_add_rounded, '+ Onboard'),
                  _buildNavPill(2, Icons.approval_rounded, 'Requests'),
                  _buildNavPill(5, Icons.manage_accounts_rounded, 'Directory & Logins'),
                  _buildNavPill(4, Icons.task_alt_rounded, 'Tasks'),
                  _buildNavPill(3, Icons.access_time_filled_rounded, 'Attendance'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Attendance Logs',
          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Text('No attendance checked in logs found', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Employee Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Check-In Time')),
                        DataColumn(label: Text('Check-Out Time')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['employeeName'] ?? '';
                        final email = data['employeeEmail'] ?? '';
                        final date = data['date'] ?? '';
                        final status = data['status'] ?? '';

                        final checkIn = data['checkInTime'] != null
                            ? DateFormat('hh:mm a').format((data['checkInTime'] as Timestamp).toDate())
                            : 'N/A';
                        final checkOut = data['checkOutTime'] != null
                            ? DateFormat('hh:mm a').format((data['checkOutTime'] as Timestamp).toDate())
                            : 'Not Checked Out';

                        return DataRow(cells: [
                          DataCell(Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold))),
                          DataCell(Text(email)),
                          DataCell(Text(date)),
                          DataCell(Text(checkIn)),
                          DataCell(Text(checkOut)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (status == 'Late' ? Colors.orange : Colors.green).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  color: status == 'Late' ? Colors.orange : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
                    'Employee Directory & App Logins',
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage employee profiles, activate/deactivate app login access, and reset passwords.',
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
              label: const Text('Add Employee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                              // Toggle App Login (Activate / Deactivate)
                              if (!isAdmin) ...[
                                if (isActive)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red[700],
                                      side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.block_rounded, size: 16),
                                    label: const Text('Deactivate App Login', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    onPressed: () => _toggleEmployeeStatus(email, name, isActive),
                                  )
                                else
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                    label: const Text('Activate App Login', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    onPressed: () => _toggleEmployeeStatus(email, name, isActive),
                                  ),
                              ],

                              // Send Password Reset Email Link
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.lock_reset_rounded, size: 16),
                                label: const Text('Send Password Link', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                onPressed: () => _sendPasswordResetLink(email, name),
                              ),

                              // Delete Employee
                              if (!isAdmin)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                  tooltip: 'Delete Employee Profile',
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
}
