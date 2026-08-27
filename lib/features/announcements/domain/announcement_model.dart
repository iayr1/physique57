import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String priority; // 'Normal', 'Important', 'Urgent'
  final String createdBy;
  final DateTime createdAt;
  final String? actionUrl;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    this.priority = 'Normal',
    required this.createdBy,
    required this.createdAt,
    this.actionUrl,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return AnnouncementModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      priority: json['priority'] as String? ?? 'Normal',
      createdBy: json['createdBy'] as String? ?? 'Admin',
      createdAt: parseDate(json['createdAt']),
      actionUrl: json['actionUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'priority': priority,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'actionUrl': actionUrl,
    };
  }
}
