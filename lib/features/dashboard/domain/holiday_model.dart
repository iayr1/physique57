class CorporateHoliday {
  final String title;
  final DateTime date;
  final String type; // 'National Holiday', 'Festival', 'Optional Holiday'
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

  static List<CorporateHoliday> getUpcomingHolidays() {
    final all = [
      CorporateHoliday(
        title: 'Janmashtami',
        date: DateTime(2026, 9, 4),
        type: 'Festival',
        description: 'Celebration of Lord Krishna\'s birthday',
      ),
      CorporateHoliday(
        title: 'Ganesh Chaturthi',
        date: DateTime(2026, 9, 14),
        type: 'Festival',
        description: 'Lord Ganesha Festival',
      ),
      CorporateHoliday(
        title: 'Id-e-Milad',
        date: DateTime(2026, 9, 25),
        type: 'Gazetted Holiday',
        description: 'Milad-un-Nabi Observance',
      ),
      CorporateHoliday(
        title: 'Mahatma Gandhi Jayanti',
        date: DateTime(2026, 10, 2),
        type: 'National Holiday',
        description: 'Birthday of Mahatma Gandhi',
      ),
      CorporateHoliday(
        title: 'Dussehra / Vijayadashami',
        date: DateTime(2026, 10, 20),
        type: 'Festival',
        description: 'Triumph of good over evil',
      ),
      CorporateHoliday(
        title: 'Diwali / Deepavali',
        date: DateTime(2026, 11, 8),
        type: 'Festival of Lights',
        description: 'Major National Festival',
      ),
      CorporateHoliday(
        title: 'Guru Nanak Jayanti',
        date: DateTime(2026, 11, 24),
        type: 'Gazetted Holiday',
        description: 'Prakash Utsav of Guru Nanak',
      ),
      CorporateHoliday(
        title: 'Christmas Day',
        date: DateTime(2026, 12, 25),
        type: 'Gazetted Holiday',
        description: 'Christmas Celebration',
      ),
    ];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return all.where((h) => !h.date.isBefore(today)).toList();
  }
}
