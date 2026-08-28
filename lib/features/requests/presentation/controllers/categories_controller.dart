import 'package:flutter_riverpod/flutter_riverpod.dart';

final categorySearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
