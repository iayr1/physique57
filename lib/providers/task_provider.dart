import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/admin/data/task_repository.dart';
import '../features/admin/domain/task_model.dart';
import 'auth_provider.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

final employeeTasksProvider = AsyncNotifierProvider<EmployeeTasksNotifier, List<TaskModel>>(() {
  return EmployeeTasksNotifier();
});

class EmployeeTasksNotifier extends AsyncNotifier<List<TaskModel>> {
  late final TaskRepository _repository;

  @override
  Future<List<TaskModel>> build() async {
    _repository = ref.watch(taskRepositoryProvider);
    final user = ref.watch(authProvider).value;
    if (user == null) return [];

    // Listen to real-time task stream
    _repository.watchEmployeeTasks(user.email).listen((tasks) {
      state = AsyncValue.data(tasks);
    });

    return _repository.getEmployeeTasks(user.email);
  }

  Future<void> reloadTasks() async {
    try {
      final user = ref.read(authProvider).value;
      if (user == null) {
        state = const AsyncValue.data([]);
        return;
      }
      final tasks = await _repository.getEmployeeTasks(user.email);
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      final user = ref.read(authProvider).value;
      await _repository.updateTaskStatus(
        taskId,
        status,
        employeeName: user?.name,
        employeeEmail: user?.email,
      );
      await reloadTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final allTasksProvider = AsyncNotifierProvider<AllTasksNotifier, List<TaskModel>>(() {
  return AllTasksNotifier();
});

class AllTasksNotifier extends AsyncNotifier<List<TaskModel>> {
  late final TaskRepository _repository;

  @override
  Future<List<TaskModel>> build() async {
    _repository = ref.watch(taskRepositoryProvider);
    _repository.watchAllTasks().listen((tasks) {
      state = AsyncValue.data(tasks);
    });
    return _repository.getAllTasks();
  }

  Future<void> reloadAllTasks() async {
    state = const AsyncValue.loading();
    try {
      final tasks = await _repository.getAllTasks();
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createTask(TaskModel task) async {
    try {
      await _repository.createTask(task);
      await reloadAllTasks();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
