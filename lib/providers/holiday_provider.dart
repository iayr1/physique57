import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/dashboard/domain/holiday_model.dart';

final holidaysStreamProvider = StreamProvider<List<CorporateHoliday>>((ref) {
  return FirebaseFirestore.instance
      .collection('holidays')
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) {
      return CorporateHoliday.getUpcomingHolidays();
    }
    final list = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return CorporateHoliday.fromJson(data);
    }).toList();

    // Sort by date ascending
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  });
});
