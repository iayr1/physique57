class EmployeeModel {
  final String id;
  final String name;
  final String email;
  final String department;
  final String designation;
  final String reportingManagerName;
  final String reportingManagerEmail;
  final String photoUrl;

  const EmployeeModel({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.designation,
    required this.reportingManagerName,
    required this.reportingManagerEmail,
    required this.photoUrl,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      department: json['department'] as String,
      designation: json['designation'] as String,
      reportingManagerName: json['reportingManagerName'] as String,
      reportingManagerEmail: json['reportingManagerEmail'] as String,
      photoUrl: json['photoUrl'] as String? ?? 'https://i.pravatar.cc/300?u=emp',
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
  );
}
