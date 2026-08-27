import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../features/admin/domain/task_model.dart';
import '../../../features/requests/domain/attendance_model.dart';
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
  DateTime? _taskDueDate = DateTime.now().add(const Duration(days: 2));

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
    super.dispose();
  }

  // Helper method to onboard a new user without signing out the current admin session
  Future<void> _onboardEmployee() async {
    if (!_onboardFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();
    final dept = _deptController.text.trim();
    final desig = _designationController.text.trim();
    final mgrName = _managerNameController.text.trim();
    final mgrEmail = _managerEmailController.text.trim();

    try {
      // 1. Create the Firebase Auth account using a secondary temporary Firebase App instance
      final tempApp = await Firebase.initializeApp(
        name: 'TempOnboardApp-${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      await tempAuth.createUserWithEmailAndPassword(email: email, password: password);
      await tempApp.delete();

      // 2. Write the Employee Profile Document into Cloud Firestore
      final newEmp = EmployeeModel(
        id: 'EMP-${1000 + email.hashCode.abs() % 8000}',
        name: name,
        email: email,
        department: dept,
        designation: desig,
        reportingManagerName: mgrName,
        reportingManagerEmail: mgrEmail,
        photoUrl: '',
      );

      await FirebaseFirestore.instance.collection('employees').doc(email).set(newEmp.toJson());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Employee $name successfully onboarded!'), backgroundColor: AppColors.statusApproved),
        );
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _deptController.clear();
        _designationController.clear();
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
    final task = TaskModel(
      id: taskId,
      title: _taskTitleController.text.trim(),
      description: _taskDescController.text.trim(),
      assignedToEmail: _taskAssigneeEmail!,
      assignedToName: _taskAssigneeName ?? _taskAssigneeEmail!,
      assignedByEmail: 'mayurailead@gmail.com',
      dueDate: _taskDueDate!,
      status: 'Pending',
      createdDate: DateTime.now(),
    );

    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).set(task.toJson());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task successfully assigned!'), backgroundColor: AppColors.statusApproved),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 260,
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
                      Text(
                        'ERMS Admin Portal',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Sidebar Options
                _buildSidebarItem(0, Icons.dashboard_outlined, 'Overview'),
                _buildSidebarItem(1, Icons.person_add_alt_1_outlined, 'Onboard Employee'),
                _buildSidebarItem(2, Icons.assignment_turned_in_outlined, 'Leave Requests'),
                _buildSidebarItem(3, Icons.co_present_rounded, 'Attendance Logs'),
                _buildSidebarItem(4, Icons.playlist_add_check_rounded, 'Task Management'),
                _buildSidebarItem(5, Icons.supervised_user_circle_outlined, 'Employee Directory'),
                const Spacer(),
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
          ),
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
        onTap: () => setState(() => _selectedTab = index),
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('employees').snapshots(),
      builder: (context, empSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('requests').snapshots(),
          builder: (context, reqSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
              builder: (context, taskSnap) {
                final totalEmployees = empSnap.hasData ? empSnap.data!.docs.length : 0;
                final pendingLeaves = reqSnap.hasData
                    ? reqSnap.data!.docs.where((doc) => doc['status'] == 'Pending Manager Approval' || doc['status'] == 'Pending HR Approval').length
                    : 0;
                final totalTasks = taskSnap.hasData ? taskSnap.data!.docs.length : 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Panel Dashboard',
                      style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildMetricCard('Total Onboarded Staff', totalEmployees.toString(), Icons.people_rounded, AppColors.primary),
                        const SizedBox(width: 20),
                        _buildMetricCard('Pending Leave Requests', pendingLeaves.toString(), Icons.receipt_long_rounded, Colors.orangeAccent),
                        const SizedBox(width: 20),
                        _buildMetricCard('Assigned Employee Tasks', totalTasks.toString(), Icons.task_alt_rounded, Colors.green),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    count,
                    style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingTab() {
    return Form(
      key: _onboardFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Onboard New Employee Profile',
            style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
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
                      validator: (v) => (v == null || !v.contains('@')) ? 'Provide a valid email' : null,
                    ),
                    CustomTextField(
                      label: 'Password for Onboarding Account',
                      hint: 'Password123!',
                      obscureText: true,
                      controller: _passwordController,
                      validator: (v) => (v == null || v.length < 6) ? 'Must be at least 6 characters' : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Department',
                            hint: 'e.g. Finance / HR',
                            controller: _deptController,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Designation',
                            hint: 'e.g. Operations Manager',
                            controller: _designationController,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Reporting Manager Name',
                            controller: _managerNameController,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'Reporting Manager Email',
                            controller: _managerEmailController,
                            validator: (v) => (v == null || !v.contains('@')) ? 'Provide a valid email' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CustomButton(
                      text: 'Onboard Employee',
                      isLoading: _isLoading,
                      onPressed: _onboardEmployee,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Leave & Category Requests Approvals',
          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 20),
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
                  final id = data['requestId'] ?? '';
                  final empName = data['employeeName'] ?? '';
                  final empEmail = data['employeeEmail'] ?? '';
                  final type = data['requestType'] ?? '';
                  final status = data['status'] ?? '';
                  
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

                  final isPending = status == 'Pending Manager Approval' || status == 'Pending HR Approval';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$empName ($empEmail)',
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text('Request Type: $type  |  ID: $id  |  Submitted: $date', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[500])),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPending ? Colors.orangeAccent.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  status,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isPending ? Colors.orange : Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isPending)
                            Row(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('requests').doc(id).update({
                                      'status': 'Approved',
                                    });
                                  },
                                  child: const Text('Approve', style: TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('requests').doc(id).update({
                                      'status': 'Rejected',
                                    });
                                  },
                                  child: const Text('Reject', style: TextStyle(color: Colors.white)),
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

  Widget _buildAttendanceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Live Attendance Logs (All Checked In/Out logs)',
          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 20),
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
                child: Container(
                  width: double.infinity,
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTasksTab() {
    return Form(
      key: _taskFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Task Management & Assignments',
            style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Assign Task Form Card
              Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign a New Task',
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Dropdown to select employee
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('employees').snapshots(),
                      builder: (context, snapshot) {
                        final list = snapshot.data?.docs ?? [];
                        return DropdownButtonFormField<String>(
                          value: _taskAssigneeEmail,
                          hint: const Text('Select Employee'),
                          items: list.map((doc) {
                            final email = doc['email'] as String;
                            final name = doc['name'] as String;
                            return DropdownMenuItem(
                              value: email,
                              child: Text(name),
                            );
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
                          validator: (v) => v == null ? 'Employee required' : null,
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
                      text: 'Assign Task',
                      isLoading: _isLoading,
                      onPressed: _assignTask,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Task List Grid
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return Center(
                        child: Text('No tasks assigned yet.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
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
                          } else {
                            final parsed = DateTime.tryParse(data['dueDate'].toString());
                            if (parsed != null) {
                              due = DateFormat('yyyy-MM-dd').format(parsed);
                            }
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
                                    Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600])),
                                const SizedBox(height: 10),
                                Text('Assigned To: $assignee  |  Due: $due', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[400])),
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
          ),
        ],
      ),
    );
  }

  Widget _buildDirectoryTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Employee Directory',
          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('employees').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Text('No employees onboarded yet.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                );
              }

              return SingleChildScrollView(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Department')),
                      DataColumn(label: Text('Designation')),
                      DataColumn(label: Text('Manager')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? '';
                      final email = data['email'] ?? '';
                      final dept = data['department'] ?? '';
                      final desig = data['designation'] ?? '';
                      final mgr = data['reportingManagerName'] ?? '';

                      return DataRow(cells: [
                        DataCell(Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold))),
                        DataCell(Text(email)),
                        DataCell(Text(dept)),
                        DataCell(Text(desig)),
                        DataCell(Text(mgr)),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            tooltip: 'Remove Employee',
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Remove Employee', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                                  content: Text('Are you sure you want to remove $name ($email) from the system? This will delete their profile from the database.'),
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
                              if (confirm == true) {
                                try {
                                  await FirebaseFirestore.instance.collection('employees').doc(doc.id).delete();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$name removed from directory'), backgroundColor: AppColors.statusApproved),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to remove: $e'), backgroundColor: AppColors.statusRejected),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ]);
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
