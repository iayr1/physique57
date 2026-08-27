import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../domain/attendance_model.dart';

class AttendanceRepository {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('attendance');

  String _getTodayDateString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  Future<void> checkIn(String email, String name) async {
    try {
      final todayStr = _getTodayDateString();
      final docId = 'ATT-$email-$todayStr';
      final now = DateTime.now();

      // Standard work start limit is 9:30 AM
      final checkInLimit = DateTime(now.year, now.month, now.day, 9, 30);
      final status = now.isAfter(checkInLimit) ? 'Late' : 'Present';

      final attendance = AttendanceModel(
        id: docId,
        employeeEmail: email,
        employeeName: name,
        checkInTime: now,
        checkOutTime: null,
        date: todayStr,
        status: status,
      );

      await _collection.doc(docId).set(attendance.toJson());
    } catch (_) {}
  }

  Future<void> checkOut(String email) async {
    try {
      final todayStr = _getTodayDateString();
      final docId = 'ATT-$email-$todayStr';
      final now = DateTime.now();

      await _collection.doc(docId).update({
        'checkOutTime': Timestamp.fromDate(now),
      });
    } catch (_) {}
  }

  Future<AttendanceModel?> getTodayAttendance(String email) async {
    try {
      final todayStr = _getTodayDateString();
      final docId = 'ATT-$email-$todayStr';
      final doc = await _collection.doc(docId).get();
      if (doc.exists && doc.data() != null) {
        return AttendanceModel.fromJson(doc.data()!);
      }
    } catch (_) {}
    return null;
  }

  Future<List<AttendanceModel>> getAllAttendanceLogs() async {
    try {
      final snapshot = await _collection.get();
      final logs = snapshot.docs.map((doc) => AttendanceModel.fromJson(doc.data())).toList();
      logs.sort((a, b) {
        if (a.checkInTime == null && b.checkInTime == null) return 0;
        if (a.checkInTime == null) return 1;
        if (b.checkInTime == null) return -1;
        return b.checkInTime!.compareTo(a.checkInTime!);
      });
      return logs;
    } catch (_) {
      return [];
    }
  }
}
