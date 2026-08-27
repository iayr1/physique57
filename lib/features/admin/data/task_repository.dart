import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/task_model.dart';

class TaskRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('tasks');

  Future<void> createTask(TaskModel task) async {
    try {
      await _collection.doc(task.id).set(task.toJson());
    } catch (_) {}
  }

  Future<List<TaskModel>> getEmployeeTasks(String email) async {
    try {
      final snapshot = await _collection.get();
      final normalizedEmail = email.trim().toLowerCase();
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromJson(doc.data()))
          .where((t) => t.assignedToEmail.trim().toLowerCase() == normalizedEmail)
          .toList();
      tasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      return tasks;
    } catch (_) {
      return [];
    }
  }

  Future<List<TaskModel>> getAllTasks() async {
    try {
      final snapshot = await _collection.get();
      final tasks = snapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList();
      tasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      return tasks;
    } catch (_) {
      return [];
    }
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    try {
      await _collection.doc(taskId).update({
        'status': status,
      });
    } catch (_) {}
  }
}
