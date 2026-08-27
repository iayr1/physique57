class EmployeeModel {
  final String id;
  final String name;
  final String email;
  final String department;
  final String designation;
  final String reportingManagerName;
  final String reportingManagerEmail;
  final String photoUrl;
  final String role; // 'admin' or 'employee'
  final bool isActive;
  final String status; // 'active' or 'deactivated'
  final Map<String, dynamic> leaveBalances;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.designation,
    required this.reportingManagerName,
    required this.reportingManagerEmail,
    required this.photoUrl,
    this.role = 'employee',
    this.isActive = true,
    this.status = 'active',
    this.leaveBalances = const {},
  });

  bool get isAdmin =>
      role == 'admin' ||
      email.trim().toLowerCase() == 'mayurailead@gmail.com' ||
      designation.toLowerCase().contains('administrator');

  static Map<String, dynamic> defaultLeaveBalances() => {
        'Annual / Paid Leave': {'total': 18, 'used': 0, 'remaining': 18},
        'Casual Leave': {'total': 10, 'used': 0, 'remaining': 10},
        'Sick Leave': {'total': 10, 'used': 0, 'remaining': 10},
        'Maternity / Paternity Leave': {'total': 90, 'used': 0, 'remaining': 90},
        'Bereavement Leave': {'total': 5, 'used': 0, 'remaining': 5},
        'Unpaid Leave': {'total': 0, 'used': 0, 'remaining': 0},
      };

  int getRemainingLeave(String type) {
    if (leaveBalances.containsKey(type)) {
      final quota = leaveBalances[type];
      if (quota is Map && quota['remaining'] != null) {
        return (quota['remaining'] as num).toInt();
      }
    }
    // Fallback to default
    final defaults = defaultLeaveBalances();
    if (defaults.containsKey(type)) {
      return (defaults[type]['remaining'] as num).toInt();
    }
    return 0;
  }

  int getTotalLeave(String type) {
    if (leaveBalances.containsKey(type)) {
      final quota = leaveBalances[type];
      if (quota is Map && quota['total'] != null) {
        return (quota['total'] as num).toInt();
      }
    }
    final defaults = defaultLeaveBalances();
    if (defaults.containsKey(type)) {
      return (defaults[type]['total'] as num).toInt();
    }
    return 0;
  }

  int getUsedLeave(String type) {
    if (leaveBalances.containsKey(type)) {
      final quota = leaveBalances[type];
      if (quota is Map && quota['used'] != null) {
        return (quota['used'] as num).toInt();
      }
    }
    return 0;
  }

  EmployeeModel copyWith({
    String? id,
    String? name,
    String? email,
    String? department,
    String? designation,
    String? reportingManagerName,
    String? reportingManagerEmail,
    String? photoUrl,
    String? role,
    bool? isActive,
    String? status,
    Map<String, dynamic>? leaveBalances,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      department: department ?? this.department,
      designation: designation ?? this.designation,
      reportingManagerName: reportingManagerName ?? this.reportingManagerName,
      reportingManagerEmail: reportingManagerEmail ?? this.reportingManagerEmail,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      leaveBalances: leaveBalances ?? this.leaveBalances,
    );
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String? ?? '';
    final defaultRole = (email.trim().toLowerCase() == 'mayurailead@gmail.com') ? 'admin' : 'employee';
    
    Map<String, dynamic> balances;
    if (json['leaveBalances'] != null && json['leaveBalances'] is Map) {
      balances = Map<String, dynamic>.from(json['leaveBalances'] as Map);
    } else {
      balances = defaultLeaveBalances();
    }

    final rawIsActive = json['isActive'];
    final bool active = rawIsActive is bool ? rawIsActive : (json['status'] != 'deactivated');

    return EmployeeModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: email,
      department: json['department'] as String? ?? '',
      designation: json['designation'] as String? ?? '',
      reportingManagerName: json['reportingManagerName'] as String? ?? '',
      reportingManagerEmail: json['reportingManagerEmail'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      role: json['role'] as String? ?? defaultRole,
      isActive: active,
      status: json['status'] as String? ?? (active ? 'active' : 'deactivated'),
      leaveBalances: balances,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'department': department,
      'designation': designation,
      'reportingManagerName': reportingManagerName,
      'reportingManagerEmail': reportingManagerEmail,
      'photoUrl': photoUrl,
      'role': role,
      'isActive': isActive,
      'status': status,
      'leaveBalances': leaveBalances.isNotEmpty ? leaveBalances : defaultLeaveBalances(),
    };
  }

  /// Default demo user (Alex Morgan)
  static const EmployeeModel demoUser = EmployeeModel(
    id: 'EMP-8842',
    name: 'Alex Morgan',
    email: 'alex.morgan@acmeglobal.com',
    department: 'Engineering & Technology',
    designation: 'Senior Software Engineer',
    reportingManagerName: 'Sarah Jenkins',
    reportingManagerEmail: 'sarah.jenkins@acmeglobal.com',
    photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=250&q=80',
    role: 'employee',
    isActive: true,
    status: 'active',
  );
}
