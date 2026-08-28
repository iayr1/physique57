import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Leave Request Form State
class LeaveFormState {
  final String leaveType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? attachmentName;
  final bool isSubmitting;

  const LeaveFormState({
    this.leaveType = 'Annual / Paid Leave',
    this.startDate,
    this.endDate,
    this.attachmentName,
    this.isSubmitting = false,
  });

  LeaveFormState copyWith({
    String? leaveType,
    DateTime? startDate,
    DateTime? endDate,
    String? attachmentName,
    bool? isSubmitting,
  }) {
    return LeaveFormState(
      leaveType: leaveType ?? this.leaveType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      attachmentName: attachmentName ?? this.attachmentName,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class LeaveFormController extends StateNotifier<LeaveFormState> {
  LeaveFormController() : super(const LeaveFormState());

  void setLeaveType(String type) => state = state.copyWith(leaveType: type);
  void setStartDate(DateTime date) => state = state.copyWith(startDate: date);
  void setEndDate(DateTime date) => state = state.copyWith(endDate: date);
  void setAttachmentName(String? name) => state = state.copyWith(attachmentName: name);
  void setSubmitting(bool submitting) => state = state.copyWith(isSubmitting: submitting);
}

final leaveFormControllerProvider = StateNotifierProvider.autoDispose<LeaveFormController, LeaveFormState>((ref) {
  return LeaveFormController();
});

// 2. Expense Request Form State
class ExpenseFormState {
  final String category;
  final DateTime? expenseDate;
  final String? receiptName;
  final bool isSubmitting;

  const ExpenseFormState({
    this.category = 'Travel & Lodging',
    this.expenseDate,
    this.receiptName,
    this.isSubmitting = false,
  });

  ExpenseFormState copyWith({
    String? category,
    DateTime? expenseDate,
    String? receiptName,
    bool? isSubmitting,
  }) {
    return ExpenseFormState(
      category: category ?? this.category,
      expenseDate: expenseDate ?? this.expenseDate,
      receiptName: receiptName ?? this.receiptName,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class ExpenseFormController extends StateNotifier<ExpenseFormState> {
  ExpenseFormController() : super(ExpenseFormState(expenseDate: DateTime.now()));

  void setCategory(String category) => state = state.copyWith(category: category);
  void setExpenseDate(DateTime date) => state = state.copyWith(expenseDate: date);
  void setReceiptName(String? name) => state = state.copyWith(receiptName: name);
  void setSubmitting(bool submitting) => state = state.copyWith(isSubmitting: submitting);
}

final expenseFormControllerProvider = StateNotifierProvider.autoDispose<ExpenseFormController, ExpenseFormState>((ref) {
  return ExpenseFormController();
});

// 3. IT Support Form State
class ITSupportFormState {
  final String issueCategory;
  final String deviceType;
  final String priority;
  final String? screenshotName;
  final bool isSubmitting;

  const ITSupportFormState({
    this.issueCategory = 'Hardware Failure',
    this.deviceType = 'MacBook / Laptop',
    this.priority = 'Medium - Impairs non-urgent work',
    this.screenshotName,
    this.isSubmitting = false,
  });

  ITSupportFormState copyWith({
    String? issueCategory,
    String? deviceType,
    String? priority,
    String? screenshotName,
    bool? isSubmitting,
  }) {
    return ITSupportFormState(
      issueCategory: issueCategory ?? this.issueCategory,
      deviceType: deviceType ?? this.deviceType,
      priority: priority ?? this.priority,
      screenshotName: screenshotName ?? this.screenshotName,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class ITSupportFormController extends StateNotifier<ITSupportFormState> {
  ITSupportFormController() : super(const ITSupportFormState());

  void setIssueCategory(String category) => state = state.copyWith(issueCategory: category);
  void setDeviceType(String type) => state = state.copyWith(deviceType: type);
  void setPriority(String priority) => state = state.copyWith(priority: priority);
  void setScreenshotName(String? name) => state = state.copyWith(screenshotName: name);
  void setSubmitting(bool submitting) => state = state.copyWith(isSubmitting: submitting);
}

final itSupportFormControllerProvider = StateNotifierProvider.autoDispose<ITSupportFormController, ITSupportFormState>((ref) {
  return ITSupportFormController();
});

// 4. Attendance Correction Form State
class AttendanceFormState {
  final DateTime? attendanceDate;
  final TimeOfDay checkIn;
  final TimeOfDay checkOut;
  final bool isSubmitting;

  const AttendanceFormState({
    this.attendanceDate,
    this.checkIn = const TimeOfDay(hour: 9, minute: 0),
    this.checkOut = const TimeOfDay(hour: 18, minute: 0),
    this.isSubmitting = false,
  });

  AttendanceFormState copyWith({
    DateTime? attendanceDate,
    TimeOfDay? checkIn,
    TimeOfDay? checkOut,
    bool? isSubmitting,
  }) {
    return AttendanceFormState(
      attendanceDate: attendanceDate ?? this.attendanceDate,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class AttendanceFormController extends StateNotifier<AttendanceFormState> {
  AttendanceFormController() : super(AttendanceFormState(attendanceDate: DateTime.now()));

  void setAttendanceDate(DateTime date) => state = state.copyWith(attendanceDate: date);
  void setCheckIn(TimeOfDay time) => state = state.copyWith(checkIn: time);
  void setCheckOut(TimeOfDay time) => state = state.copyWith(checkOut: time);
  void setSubmitting(bool submitting) => state = state.copyWith(isSubmitting: submitting);
}

final attendanceFormControllerProvider = StateNotifierProvider.autoDispose<AttendanceFormController, AttendanceFormState>((ref) {
  return AttendanceFormController();
});

// 5. Work From Home Form State
class WFHFormState {
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isSubmitting;

  const WFHFormState({
    this.startDate,
    this.endDate,
    this.isSubmitting = false,
  });

  WFHFormState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    bool? isSubmitting,
  }) {
    return WFHFormState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class WFHFormController extends StateNotifier<WFHFormState> {
  WFHFormController() : super(const WFHFormState());

  void setStartDate(DateTime date) => state = state.copyWith(startDate: date);
  void setEndDate(DateTime date) => state = state.copyWith(endDate: date);
  void setSubmitting(bool submitting) => state = state.copyWith(isSubmitting: submitting);
}

final wfhFormControllerProvider = StateNotifierProvider.autoDispose<WFHFormController, WFHFormState>((ref) {
  return WFHFormController();
});

// 6. HR Inquiry Form State
class HRFormState {
  final String category;
  final bool isConfidential;
  final bool isSubmitting;

  const HRFormState({
    this.category = 'General Inquiry',
    this.isConfidential = false,
    this.isSubmitting = false,
  });

  HRFormState copyWith({
    String? category,
    bool? isConfidential,
    bool? isSubmitting,
  }) {
    return HRFormState(
      category: category ?? this.category,
      isConfidential: isConfidential ?? this.isConfidential,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class HRFormController extends StateNotifier<HRFormState> {
  HRFormController() : super(const HRFormState());

  void setCategory(String category) => state = state.copyWith(category: category);
  void setConfidential(bool confidential) => state = state.copyWith(isConfidential: confidential);
  void setSubmitting(bool submitting) => state = state.copyWith(isSubmitting: submitting);
}

final hrFormControllerProvider = StateNotifierProvider.autoDispose<HRFormController, HRFormState>((ref) {
  return HRFormController();
});

// 7. Travel Request Form State
class TravelFormState {
  final DateTime? startDate;
  final DateTime? endDate;
  final String travelMode;
  final bool isSubmitting;

  const TravelFormState({
    this.startDate,
    this.endDate,
    this.travelMode = 'Flight',
    this.isSubmitting = false,
  });

  TravelFormState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? travelMode,
    bool? isSubmitting,
  }) {
    return TravelFormState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      travelMode: travelMode ?? this.travelMode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class TravelFormController extends StateNotifier<TravelFormState> {
  TravelFormController() : super(const TravelFormState());

  void setStartDate(DateTime date) => state = state.copyWith(startDate: date);
  void setEndDate(DateTime date) => state = state.copyWith(endDate: date);
  void setTravelMode(String mode) => state = state.copyWith(travelMode: mode);
  void setSubmitting(bool submitting) => state = state.copyWith(isSubmitting: submitting);
}

final travelFormControllerProvider = StateNotifierProvider.autoDispose<TravelFormController, TravelFormState>((ref) {
  return TravelFormController();
});

// 8. Generic Request Form State
class GenericFormState {
  final String? attachmentName;
  final bool isSubmitting;

  const GenericFormState({
    this.attachmentName,
    this.isSubmitting = false,
  });

  GenericFormState copyWith({
    String? attachmentName,
    bool? isSubmitting,
  }) {
    return GenericFormState(
      attachmentName: attachmentName ?? this.attachmentName,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class GenericFormController extends StateNotifier<GenericFormState> {
  GenericFormController() : super(const GenericFormState());

  void setAttachmentName(String? name) => state = state.copyWith(attachmentName: name);
  void setSubmitting(bool submitting) => state = state.copyWith(isSubmitting: submitting);
}

final genericFormControllerProvider = StateNotifierProvider.autoDispose<GenericFormController, GenericFormState>((ref) {
  return GenericFormController();
});
