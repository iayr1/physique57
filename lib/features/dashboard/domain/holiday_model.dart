import 'package:cloud_firestore/cloud_firestore.dart';

class CorporateHoliday {
  final String title;
  final DateTime date;
  final String type; // 'National Holiday', 'Festival', 'Gazetted Holiday'
  final String description;

  const CorporateHoliday({
    required this.title,
    required this.date,
    required this.type,
    required this.description,
  });

  int get daysUntil {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  String get countdownText {
    final days = daysUntil;
    if (days == 0) return 'Today 🎉';
    if (days == 1) return 'Tomorrow ⚡';
    if (days < 0) return '${days.abs()}d ago';
    return 'In $days Days';
  }

  factory CorporateHoliday.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate = DateTime.now();
    if (json['date'] != null) {
      if (json['date'] is Timestamp) {
        parsedDate = (json['date'] as Timestamp).toDate();
      } else if (json['date'] is String) {
        parsedDate = DateTime.tryParse(json['date']) ?? DateTime.now();
      }
    }

    return CorporateHoliday(
      title: json['title'] ?? '',
      date: parsedDate,
      type: json['type'] ?? 'Holiday',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'type': type,
      'description': description,
    };
  }

  static List<CorporateHoliday> getUpcomingHolidays() {
    final now = DateTime.now();
    final currentYear = now.year;

    final all = [
      CorporateHoliday(
        title: 'Janmashtami',
        date: DateTime(currentYear, 9, 4),
        type: 'Festival',
        description: 'Celebration of Lord Krishna\'s birthday',
      ),
      CorporateHoliday(
        title: 'Ganesh Chaturthi',
        date: DateTime(currentYear, 9, 14),
        type: 'Festival',
        description: 'Lord Ganesha Festival',
      ),
      CorporateHoliday(
        title: 'Id-e-Milad',
        date: DateTime(currentYear, 9, 25),
        type: 'Gazetted Holiday',
        description: 'Milad-un-Nabi Observance',
      ),
      CorporateHoliday(
        title: 'Mahatma Gandhi Jayanti',
        date: DateTime(currentYear, 10, 2),
        type: 'National Holiday',
        description: 'Birthday of Mahatma Gandhi',
      ),
      CorporateHoliday(
        title: 'Dussehra / Vijayadashami',
        date: DateTime(currentYear, 10, 20),
        type: 'Festival',
        description: 'Triumph of good over evil',
      ),
      CorporateHoliday(
        title: 'Diwali / Deepavali',
        date: DateTime(currentYear, 11, 8),
        type: 'Festival of Lights',
        description: 'Major National Festival',
      ),
      CorporateHoliday(
        title: 'Guru Nanak Jayanti',
        date: DateTime(currentYear, 11, 24),
        type: 'Gazetted Holiday',
        description: 'Prakash Utsav of Guru Nanak',
      ),
      CorporateHoliday(
        title: 'Christmas Day',
        date: DateTime(currentYear, 12, 25),
        type: 'Gazetted Holiday',
        description: 'Christmas Celebration',
      ),
      CorporateHoliday(
        title: 'New Year\'s Day',
        date: DateTime(currentYear + 1, 1, 1),
        type: 'National Holiday',
        description: 'Celebration of the New Year',
      ),
      CorporateHoliday(
        title: 'Republic Day',
        date: DateTime(currentYear + 1, 1, 26),
        type: 'National Holiday',
        description: 'Constitution of India Celebration',
      ),
    ];

    final today = DateTime(now.year, now.month, now.day);
    return all.where((h) => !h.date.isBefore(today)).toList();
  }
}
