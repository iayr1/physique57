import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('tasks');

  Future<void> createTask(TaskModel task) async {
    await _collection.doc(task.id).set(task.toJson());
  }

  Future<List<TaskModel>> getEmployeeTasks(String email) async {
    final snapshot = await _collection.where('assignedToEmail', isEqualTo: email).get();
    final tasks = snapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList();
    tasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return tasks;
  }

  Future<List<TaskModel>> getAllTasks() async {
    final snapshot = await _collection.get();
    final tasks = snapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList();
    tasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return tasks;
  }

  Future<void> updateTaskStatus(String taskId, String status) async {
    await _collection.doc(taskId).update({
      'status': status,
    });
  }
}
