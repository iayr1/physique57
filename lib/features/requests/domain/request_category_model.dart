import 'package:flutter/material.dart';

enum RequestType {
  leave,
  expense,
  itSupport,
  hrRequest,
  attendance,
  workFromHome,
  travel,
  other;

  String get title {
    switch (this) {
      case RequestType.leave:
        return 'Leave Request';
      case RequestType.expense:
        return 'Expense Request';
      case RequestType.itSupport:
        return 'IT Support';
      case RequestType.hrRequest:
        return 'HR Request';
      case RequestType.attendance:
        return 'Attendance Correction';
      case RequestType.workFromHome:
        return 'Work From Home';
      case RequestType.travel:
        return 'Travel Request';
      case RequestType.other:
        return 'Other Request';
    }
  }

  String get description {
    switch (this) {
      case RequestType.leave:
        return 'Apply for casual, sick, or annual leave with automatic balance calculation.';
      case RequestType.expense:
        return 'Submit business travel, office, or client meal receipts for reimbursement.';
      case RequestType.itSupport:
        return 'Report hardware bugs, request software access, or hardware upgrades.';
      case RequestType.hrRequest:
        return 'Inquire regarding payroll, benefits, policies, or HR assistance.';
      case RequestType.attendance:
        return 'Correct missed clock-in/out timestamps with manager justification.';
      case RequestType.workFromHome:
        return 'Request remote work approval for specific dates or long-term.';
      case RequestType.travel:
        return 'Submit official business trip itineraries and advance requests.';
      case RequestType.other:
        return 'Submit any general workplace request not covered above.';
    }
  }

  IconData get icon {
    switch (this) {
      case RequestType.leave:
        return Icons.calendar_month_rounded;
      case RequestType.expense:
        return Icons.receipt_long_rounded;
      case RequestType.itSupport:
        return Icons.devices_rounded;
      case RequestType.hrRequest:
        return Icons.people_alt_rounded;
      case RequestType.attendance:
        return Icons.access_time_filled_rounded;
      case RequestType.workFromHome:
        return Icons.home_work_rounded;
      case RequestType.travel:
        return Icons.flight_takeoff_rounded;
      case RequestType.other:
        return Icons.widgets_rounded;
    }
  }

  Color get color {
    switch (this) {
      case RequestType.leave:
        return const Color(0xFF3B82F6);
      case RequestType.expense:
        return const Color(0xFF10B981);
      case RequestType.itSupport:
        return const Color(0xFF8B5CF6);
      case RequestType.hrRequest:
        return const Color(0xFFEC4899);
      case RequestType.attendance:
        return const Color(0xFFF59E0B);
      case RequestType.workFromHome:
        return const Color(0xFF06B6D4);
      case RequestType.travel:
        return const Color(0xFF6366F1);
      case RequestType.other:
        return const Color(0xFF64748B);
    }
  }
}
