import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that returns the current DateTime.
/// In tests, this can be overridden to simulate different times.
final currentTimeProvider = Provider<DateTime>((ref) => DateTime.now());
