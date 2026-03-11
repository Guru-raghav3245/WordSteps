import 'package:flutter_riverpod/legacy.dart';

// Moved from SettingsScreen to be accessible globally
final volumeProvider = StateProvider<double>((ref) => 1.0);
final pitchProvider = StateProvider<double>((ref) => 1.0);
final speechRateProvider = StateProvider<double>((ref) => 0.5);