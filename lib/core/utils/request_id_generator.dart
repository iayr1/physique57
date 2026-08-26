import 'dart:math';

class RequestIdGenerator {
  /// Generates a unique request ID adhering to the format `REQ-YYYY-XXXXXX`
  /// e.g. REQ-2026-001245
  static String generate({int? index}) {
    final year = DateTime.now().year.toString();
    final randomNum = index ?? Random().nextInt(899999) + 100000;
    final paddedNumber = randomNum.toString().padLeft(6, '0');
    return 'REQ-$year-$paddedNumber';
  }
}
