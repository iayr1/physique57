import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  final String id;
  final String title;
  final String description;
  final String assignedToEmail;
  final String assignedToName;
  final String assignedByEmail;
  final DateTime dueDate;
  final String status; // 'Pending', 'In Progress', 'Completed'
  final DateTime createdDate;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedToEmail,
    required this.assignedToName,
    required this.assignedByEmail,
    required this.dueDate,
    required this.status,
    required this.createdDate,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic field, {DateTime? fallback}) {
      if (field == null) return fallback ?? DateTime.now();
      if (field is Timestamp) return field.toDate();
      if (field is DateTime) return field;
      final parsed = DateTime.tryParse(field.toString());
      return parsed ?? (fallback ?? DateTime.now());
    }

    // Check createdDate then createdAt
    final created = parseDate(json['createdDate'] ?? json['createdAt']);

    // Check dueDate then fallback to end of day if present, or created date + 7 days
    final due = json['dueDate'] != null
        ? parseDate(json['dueDate'], fallback: created.add(const Duration(days: 7)))
        : created.add(const Duration(days: 7));

    return TaskModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      assignedToEmail: json['assignedToEmail'] as String? ?? '',
      assignedToName: json['assignedToName'] as String? ?? '',
      assignedByEmail: (json['assignedByEmail'] as String?)?.isNotEmpty == true
          ? json['assignedByEmail'] as String
          : (json['assignedBy'] as String? ?? ''),
      dueDate: due,
      status: json['status'] as String? ?? 'Pending',
      createdDate: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assignedToEmail': assignedToEmail,
      'assignedToName': assignedToName,
      'assignedByEmail': assignedByEmail,
      'assignedBy': assignedByEmail,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'createdDate': Timestamp.fromDate(createdDate),
      'createdAt': Timestamp.fromDate(createdDate),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedToEmail,
    String? assignedToName,
    String? assignedByEmail,
    DateTime? dueDate,
    String? status,
    DateTime? createdDate,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedByEmail: assignedByEmail ?? this.assignedByEmail,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdDate: createdDate ?? this.createdDate,
    );
  }
}
