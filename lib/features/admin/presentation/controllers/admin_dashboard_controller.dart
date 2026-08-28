import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminDashboardState {
  final int selectedTab;
  final bool isLoading;
  final String searchDirectoryQuery;
  final DateTime selectedAttendanceDate;
  final String attendanceSearchQuery;
  final String attendanceFilterStatus;
  final int attendanceTabMode;
  final String announcementPriority;
  final String auditSearchQuery;
  final String? taskAssigneeEmail;
  final String? taskAssigneeName;

  AdminDashboardState({
    this.selectedTab = 0,
    this.isLoading = false,
    this.searchDirectoryQuery = '',
    DateTime? selectedAttendanceDate,
    this.attendanceSearchQuery = '',
    this.attendanceFilterStatus = 'All',
    this.attendanceTabMode = 0,
    this.announcementPriority = 'Normal',
    this.auditSearchQuery = '',
    this.taskAssigneeEmail,
    this.taskAssigneeName,
  }) : selectedAttendanceDate = selectedAttendanceDate ?? DateTime.now();

  AdminDashboardState copyWith({
    int? selectedTab,
    bool? isLoading,
    String? searchDirectoryQuery,
    DateTime? selectedAttendanceDate,
    String? attendanceSearchQuery,
    String? attendanceFilterStatus,
    int? attendanceTabMode,
    String? announcementPriority,
    String? auditSearchQuery,
    String? taskAssigneeEmail,
    String? taskAssigneeName,
  }) {
    return AdminDashboardState(
      selectedTab: selectedTab ?? this.selectedTab,
      isLoading: isLoading ?? this.isLoading,
      searchDirectoryQuery: searchDirectoryQuery ?? this.searchDirectoryQuery,
      selectedAttendanceDate: selectedAttendanceDate ?? this.selectedAttendanceDate,
      attendanceSearchQuery: attendanceSearchQuery ?? this.attendanceSearchQuery,
      attendanceFilterStatus: attendanceFilterStatus ?? this.attendanceFilterStatus,
      attendanceTabMode: attendanceTabMode ?? this.attendanceTabMode,
      announcementPriority: announcementPriority ?? this.announcementPriority,
      auditSearchQuery: auditSearchQuery ?? this.auditSearchQuery,
      taskAssigneeEmail: taskAssigneeEmail ?? this.taskAssigneeEmail,
      taskAssigneeName: taskAssigneeName ?? this.taskAssigneeName,
    );
  }
}

class AdminDashboardController extends StateNotifier<AdminDashboardState> {
  AdminDashboardController() : super(AdminDashboardState());

  void setSelectedTab(int tab) => state = state.copyWith(selectedTab: tab);
  void setLoading(bool loading) => state = state.copyWith(isLoading: loading);
  void setSearchDirectoryQuery(String query) => state = state.copyWith(searchDirectoryQuery: query);
  void setSelectedAttendanceDate(DateTime date) => state = state.copyWith(selectedAttendanceDate: date);
  void setAttendanceSearchQuery(String query) => state = state.copyWith(attendanceSearchQuery: query);
  void setAttendanceFilterStatus(String status) => state = state.copyWith(attendanceFilterStatus: status);
  void setAttendanceTabMode(int mode) => state = state.copyWith(attendanceTabMode: mode);
  void setAnnouncementPriority(String priority) => state = state.copyWith(announcementPriority: priority);
  void setAuditSearchQuery(String query) => state = state.copyWith(auditSearchQuery: query);
  void setTaskAssignee({required String? email, required String? name}) {
    state = state.copyWith(taskAssigneeEmail: email, taskAssigneeName: name);
  }
}

final adminDashboardControllerProvider = StateNotifierProvider.autoDispose<AdminDashboardController, AdminDashboardState>((ref) {
  return AdminDashboardController();
});
