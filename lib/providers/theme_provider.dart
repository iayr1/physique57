import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BackendType { mock, googleSheets, firebase }

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

final backendTypeProvider = StateProvider<BackendType>((ref) => BackendType.firebase);
