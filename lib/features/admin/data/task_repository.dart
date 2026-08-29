import 'package:cloud_firestore/cloud_firestore.dart';
import '../../audit/data/audit_repository.dart';
import '../domain/task_model.dart';

class TaskRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final AuditRepository _auditRepo = AuditRepository();

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('tasks');

  Future<void> createTask(TaskModel task) async {
    try {
      await _collection.doc(task.id).set(task.toJson());

      // Automated Notification to Assignee
      final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
      await _firestore.collection('notifications').doc(notifId).set({
        'id': notifId,
        'title': '📋 New Task Assigned: ${task.title}',
        'message': task.description.isNotEmpty
            ? task.description
            : 'You have been assigned a new task by ${task.assignedByEmail}.',
        'requestId': task.id,
        'timestamp': Timestamp.now(),
        'isRead': false,
        'recipientEmail': task.assignedToEmail,
      });

      // Audit log
      await _auditRepo.logAction(
        action: 'TASK_ASSIGNED',
        performedBy: task.assignedByEmail,
        targetEmail: task.assignedToEmail,
        details: 'Task: ${task.title} (${task.id})',
      );
    } catch (_) {}
  }

  Stream<List<TaskModel>> watchEmployeeTasks(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    return _collection.snapshots().map((snapshot) {
      final tasks = snapshot.docs
          .map((doc) => TaskModel.fromJson(doc.data()))
          .where((t) => t.assignedToEmail.trim().toLowerCase() == normalizedEmail)
          .toList();
      tasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      return tasks;
    });
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

  Stream<List<TaskModel>> watchAllTasks() {
    return _collection.snapshots().map((snapshot) {
      final tasks = snapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList();
      tasks.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      return tasks;
    });
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

  Future<void> updateTaskStatus(String taskId, String status, {String? employeeName, String? employeeEmail}) async {
    try {
      await _collection.doc(taskId).update({
        'status': status,
      });

      // If completed, notify admin
      if (status == 'Completed') {
        final doc = await _collection.doc(taskId).get();
        final taskTitle = doc.data()?['title'] ?? 'Task';
        final assigner = doc.data()?['assignedByEmail'] ?? 'admin@physique57.com';
        final performer = employeeName ?? doc.data()?['assignedToName'] ?? 'Employee';

        final notifId = 'NOTIF-${DateTime.now().millisecondsSinceEpoch}';
        await _firestore.collection('notifications').doc(notifId).set({
          'id': notifId,
          'title': '✓ Task Completed',
          'message': '$performer has marked task "$taskTitle" as Completed.',
          'requestId': taskId,
          'timestamp': Timestamp.now(),
          'isRead': false,
          'recipientEmail': assigner,
        });

        await _auditRepo.logAction(
          action: 'TASK_COMPLETED',
          performedBy: employeeEmail ?? performer,
          targetEmail: assigner,
          details: 'Task "$taskTitle" ($taskId) completed',
        );
      }
    } catch (_) {}
  }
}
