import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardTaskFilterProvider = StateProvider.autoDispose<String>((ref) => 'All');
