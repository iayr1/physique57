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
    return TaskModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      assignedToEmail: json['assignedToEmail'] as String? ?? '',
      assignedToName: json['assignedToName'] as String? ?? '',
      assignedByEmail: json['assignedByEmail'] as String? ?? '',
      dueDate: json['dueDate'] != null
          ? (json['dueDate'] is Timestamp
              ? (json['dueDate'] as Timestamp).toDate()
              : DateTime.tryParse(json['dueDate'].toString()) ?? DateTime.now())
          : DateTime.now(),
      status: json['status'] as String? ?? 'Pending',
      createdDate: json['createdDate'] != null
          ? (json['createdDate'] is Timestamp
              ? (json['createdDate'] as Timestamp).toDate()
              : DateTime.tryParse(json['createdDate'].toString()) ?? DateTime.now())
          : DateTime.now(),
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
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'createdDate': Timestamp.fromDate(createdDate),
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
