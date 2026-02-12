import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/services/logger_service.dart';

void main() {
  group('LoggerService Tests', () {
    late LoggerService logger;

    setUp(() {
      logger = LoggerService();
      logger.setMinLevel(LogLevel.debug);
      logger.clearLogs();
    });

    test('Log buffer should contain entries after clearLogs', () {
      // clearLogs adds "Log buffer cleared"
      final logs = logger.getRecentLogs();
      expect(logs.any((e) => e.message.contains('Log buffer cleared')), true);
    });

    test('Filtering by minLevel', () {
      logger.setMinLevel(LogLevel.warning);
      logger.info('T', 'Skip');
      logger.error('T', 'Keep');

      final logs = logger.getRecentLogs();
      expect(logs.any((e) => e.message == 'Keep'), true);
      expect(logs.any((e) => e.message == 'Skip'), false);
    });

    test('Performance tracking logs', () {
      final sw = logger.startOperation('test-op');
      logger.endOperation(sw, 'test-op');

      final logs = logger.getRecentLogs();
      expect(logs.any((e) => e.message.contains('test-op completed')), true);
      expect(logs.any((e) => e.tag == 'Performance'), true);
    });

    test('LogEntry serialization', () {
      final entry = LogEntry(
        level: LogLevel.info,
        tag: 'T',
        message: 'M',
        timestamp: DateTime.now(),
        metadata: {'k': 'v'},
      );
      final map = entry.toMap();
      expect(map['level'], 'info');
      expect(map['metadata']['k'], 'v');
    });
  });
}
