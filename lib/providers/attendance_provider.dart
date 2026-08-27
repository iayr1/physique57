import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/requests/data/attendance_repository.dart';
import '../features/requests/domain/attendance_model.dart';
import 'auth_provider.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

final todayAttendanceProvider = AsyncNotifierProvider<TodayAttendanceNotifier, AttendanceModel?>(() {
  return TodayAttendanceNotifier();
});

class TodayAttendanceNotifier extends AsyncNotifier<AttendanceModel?> {
  late final AttendanceRepository _repository;

  @override
  Future<AttendanceModel?> build() async {
    _repository = ref.watch(attendanceRepositoryProvider);
    final user = ref.watch(authProvider).value;
    if (user == null) return null;
    return _repository.getTodayAttendance(user.email);
  }

  Future<void> checkIn() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    state = const AsyncValue.loading();
    try {
      await _repository.checkIn(user.email, user.name);
      final updated = await _repository.getTodayAttendance(user.email);
      state = AsyncValue.data(updated);
      ref.invalidate(allAttendanceLogsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> checkOut() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    state = const AsyncValue.loading();
    try {
      await _repository.checkOut(user.email);
      final updated = await _repository.getTodayAttendance(user.email);
      state = AsyncValue.data(updated);
      ref.invalidate(allAttendanceLogsProvider);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final allAttendanceLogsProvider = FutureProvider<List<AttendanceModel>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getAllAttendanceLogs();
});

/// Dynamic Attendance Streak Engine
final employeeAttendanceStreakProvider = Provider<int>((ref) {
  final user = ref.watch(authProvider).valueOrNull;
  final allLogsAsync = ref.watch(allAttendanceLogsProvider);
  if (user == null) return 1;

  return allLogsAsync.maybeWhen(
    data: (logs) {
      final userLogs = logs
          .where((l) => l.employeeEmail.trim().toLowerCase() == user.email.trim().toLowerCase())
          .toList();
      if (userLogs.isEmpty) return 1;

      int streak = 0;
      final sorted = List<AttendanceModel>.from(userLogs)
        ..sort((a, b) => b.date.compareTo(a.date));

      DateTime checkDate = DateTime.now();
      for (final log in sorted) {
        final logDate = DateTime.tryParse(log.date);
        if (logDate == null) continue;
        final diff = checkDate.difference(logDate).inDays;
        if (diff <= 1 && log.status != 'Absent') {
          streak++;
          checkDate = logDate;
        } else if (diff > 1) {
          break;
        }
      }
      return streak > 0 ? streak : 1;
    },
    orElse: () => 1,
  );
});
