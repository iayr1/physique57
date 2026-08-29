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
  final Map<String, dynamic> healthProfile;
  final double baseSalary;
  final double hraPercentage;
  final double allowancePercentage;
  final double pfPercentage;
  final double overtimeRate;
  final double monthlyIncentive;
  final String payStatus;
  final String payCycle;
  final String phoneNumber;
  final String joiningDate;

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
    this.healthProfile = const {},
    this.baseSalary = 65000.0,
    this.hraPercentage = 40.0,
    this.allowancePercentage = 15.0,
    this.pfPercentage = 8.0,
    this.overtimeRate = 500.0,
    this.monthlyIncentive = 5000.0,
    this.payStatus = 'Processed',
    this.payCycle = 'Monthly',
    this.phoneNumber = '',
    this.joiningDate = '',
  });

  bool get isAdmin =>
      role.toLowerCase().trim() == 'admin' ||
      designation.toLowerCase().contains('administrator') ||
      designation.toLowerCase().contains('admin');

  // Dynamic Compensation Calculations
  double get hraAmount => (baseSalary * (hraPercentage / 100.0)).roundToDouble();
  double get allowanceAmount => (baseSalary * (allowancePercentage / 100.0)).roundToDouble();
  double get pfDeduction => (baseSalary * (pfPercentage / 100.0)).roundToDouble();
  double get grossSalary => baseSalary + hraAmount + allowanceAmount + monthlyIncentive;
  double get netTakeHomePay => grossSalary - pfDeduction;

  // Dynamic Health & Insurance Profile Getters
  String get mediclaimId => healthProfile['mediclaimId'] as String? ?? 'PHY57-MED-${1000 + email.hashCode.abs() % 8999}';
  double get coverageAmount => (healthProfile['coverageAmount'] as num?)?.toDouble() ?? 500000.0;
  String get bloodGroup => healthProfile['bloodGroup'] as String? ?? 'O+';
  String get emergencyContactName => healthProfile['emergencyContactName'] as String? ?? (reportingManagerName.isNotEmpty ? reportingManagerName : 'Family Contact');
  String get emergencyContactPhone => healthProfile['emergencyContactPhone'] as String? ?? '+91 98765 43210';
  double get wellnessAllowance => (healthProfile['wellnessAllowance'] as num?)?.toDouble() ?? 15000.0;
  bool get healthCheckupDone => healthProfile['healthCheckupDone'] as bool? ?? true;

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
    Map<String, dynamic>? healthProfile,
    double? baseSalary,
    double? hraPercentage,
    double? allowancePercentage,
    double? pfPercentage,
    double? overtimeRate,
    double? monthlyIncentive,
    String? payStatus,
    String? payCycle,
    String? phoneNumber,
    String? joiningDate,
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
      healthProfile: healthProfile ?? this.healthProfile,
      baseSalary: baseSalary ?? this.baseSalary,
      hraPercentage: hraPercentage ?? this.hraPercentage,
      allowancePercentage: allowancePercentage ?? this.allowancePercentage,
      pfPercentage: pfPercentage ?? this.pfPercentage,
      overtimeRate: overtimeRate ?? this.overtimeRate,
      monthlyIncentive: monthlyIncentive ?? this.monthlyIncentive,
      payStatus: payStatus ?? this.payStatus,
      payCycle: payCycle ?? this.payCycle,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      joiningDate: joiningDate ?? this.joiningDate,
    );
  }

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final email = json['email'] as String? ?? '';
    final role = (json['role'] as String? ?? 'employee').trim();

    Map<String, dynamic> balances;
    if (json['leaveBalances'] != null && json['leaveBalances'] is Map) {
      balances = Map<String, dynamic>.from(json['leaveBalances'] as Map);
    } else {
      balances = defaultLeaveBalances();
    }

    Map<String, dynamic> hpMap = {};
    if (json['healthProfile'] != null && json['healthProfile'] is Map) {
      hpMap = Map<String, dynamic>.from(json['healthProfile'] as Map);
    }

    final rawIsActive = json['isActive'];
    final bool active = rawIsActive is bool ? rawIsActive : (json['status'] != 'deactivated');

    double parseDouble(dynamic val, double fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? fallback;
    }

    double salary = parseDouble(json['baseSalary'] ?? json['salary'], 65000.0);

    final rawMgrName = json['reportingManagerName'] as String? ?? '';
    final rawMgrEmail = json['reportingManagerEmail'] as String? ?? '';
    final mgrName = rawMgrName.trim().isNotEmpty ? rawMgrName.trim() : 'Mayur Chaudhari';
    final mgrEmail = rawMgrEmail.trim().isNotEmpty ? rawMgrEmail.trim() : 'mayurchaudhari@gmail.com';

    return EmployeeModel(
      id: json['id'] as String? ?? 'EMP-${1000 + email.hashCode.abs() % 8000}',
      name: json['name'] as String? ?? (email.isNotEmpty ? email.split('@').first : 'Employee'),
      email: email,
      department: json['department'] as String? ?? 'Physique 57 Operations',
      designation: json['designation'] as String? ?? 'Team Specialist',
      reportingManagerName: mgrName,
      reportingManagerEmail: mgrEmail,
      photoUrl: json['photoUrl'] as String? ?? '',
      role: role,
      isActive: active,
      status: json['status'] as String? ?? (active ? 'active' : 'deactivated'),
      leaveBalances: balances,
      healthProfile: hpMap,
      baseSalary: salary,
      hraPercentage: parseDouble(json['hraPercentage'], 40.0),
      allowancePercentage: parseDouble(json['allowancePercentage'], 15.0),
      pfPercentage: parseDouble(json['pfPercentage'], 8.0),
      overtimeRate: parseDouble(json['overtimeRate'], 500.0),
      monthlyIncentive: parseDouble(json['monthlyIncentive'], 5000.0),
      payStatus: json['payStatus'] as String? ?? 'Processed',
      payCycle: json['payCycle'] as String? ?? 'Monthly',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      joiningDate: json['joiningDate'] as String? ?? '',
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
      'healthProfile': healthProfile,
      'baseSalary': baseSalary,
      'hraPercentage': hraPercentage,
      'allowancePercentage': allowancePercentage,
      'pfPercentage': pfPercentage,
      'overtimeRate': overtimeRate,
      'monthlyIncentive': monthlyIncentive,
      'payStatus': payStatus,
      'payCycle': payCycle,
      'phoneNumber': phoneNumber,
      'joiningDate': joiningDate,
    };
  }
}
