import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  final String id;
  final String action; // e.g. 'USER_ONBOARDED', 'LEAVE_APPROVED', 'ATTENDANCE_OVERRIDE'
  final String performedBy;
  final String targetEmail;
  final String details;
  final DateTime timestamp;

  const AuditLogModel({
    required this.id,
    required this.action,
    required this.performedBy,
    required this.targetEmail,
    required this.details,
    required this.timestamp,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return AuditLogModel(
      id: json['id'] as String? ?? '',
      action: json['action'] as String? ?? 'SYSTEM_EVENT',
      performedBy: json['performedBy'] as String? ?? 'Admin',
      targetEmail: json['targetEmail'] as String? ?? '',
      details: json['details'] as String? ?? '',
      timestamp: parseDate(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'performedBy': performedBy,
      'targetEmail': targetEmail,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
