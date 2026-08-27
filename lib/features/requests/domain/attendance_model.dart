import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String employeeEmail;
  final String employeeName;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String date; // format: YYYY-MM-DD
  final String status; // 'Present', 'Late', 'CheckedIn', 'Absent'

  const AttendanceModel({
    required this.id,
    required this.employeeEmail,
    required this.employeeName,
    this.checkInTime,
    this.checkOutTime,
    required this.date,
    required this.status,
  });

  Duration? get duration {
    if (checkInTime != null && checkOutTime != null) {
      return checkOutTime!.difference(checkInTime!);
    }
    return null;
  }

  String get formattedDuration {
    final d = duration;
    if (d == null) return checkInTime != null ? 'In Progress' : '—';
    final hours = d.inHours;
    final mins = d.inMinutes.remainder(60);
    return '${hours}h ${mins}m';
  }

  bool get isLate => status == 'Late';

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] as String? ?? '',
      employeeEmail: json['employeeEmail'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      checkInTime: json['checkInTime'] != null
          ? (json['checkInTime'] is Timestamp
              ? (json['checkInTime'] as Timestamp).toDate()
              : DateTime.tryParse(json['checkInTime'].toString()))
          : null,
      checkOutTime: json['checkOutTime'] != null
          ? (json['checkOutTime'] is Timestamp
              ? (json['checkOutTime'] as Timestamp).toDate()
              : DateTime.tryParse(json['checkOutTime'].toString()))
          : null,
      date: json['date'] as String? ?? '',
      status: json['status'] as String? ?? 'Absent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeEmail': employeeEmail,
      'employeeName': employeeName,
      'checkInTime': checkInTime != null ? Timestamp.fromDate(checkInTime!) : null,
      'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'date': date,
      'status': status,
    };
  }

  AttendanceModel copyWith({
    String? id,
    String? employeeEmail,
    String? employeeName,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? date,
    String? status,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      employeeEmail: employeeEmail ?? this.employeeEmail,
      employeeName: employeeName ?? this.employeeName,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      date: date ?? this.date,
      status: status ?? this.status,
    );
  }
}
