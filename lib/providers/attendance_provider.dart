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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final allAttendanceLogsProvider = FutureProvider<List<AttendanceModel>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.getAllAttendanceLogs();
});
