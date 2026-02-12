import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/services/logger_service.dart';

void main() {
  group('LoggerService Tests', () {
    late LoggerService logger;

    setUp(() {
      logger = LoggerService();
      logger.clearLogs();
      logger.setMinLevel(LogLevel.debug);
    });

    test('LoggerService is a singleton', () {
      expect(LoggerService(), same(LoggerService()));
    });

    test('Log levels prefix are correct', () {
      final entry = LogEntry(
        level: LogLevel.error,
        tag: 'Test',
        message: 'Msg',
        timestamp: DateTime.now(),
      );
      expect(entry.levelPrefix, '[ERROR]');
    });

    test('Log buffer limits entries', () {
      // LoggerService has maxBufferSize = 500
      for (int i = 0; i < 600; i++) {
        logger.info('Tag', 'Message $i');
      }

      final logs = logger.getRecentLogs(count: 1000);
      expect(logs.length, 500);
      expect(logs.first.message, contains('Message 599'));
    });

    test('Filtering by minLevel works', () {
      logger.setMinLevel(LogLevel.warning);

      logger.debug('T', 'Debug msg');
      logger.info('T', 'Info msg');
      logger.warning('T', 'Warning msg');
      logger.error('T', 'Error msg');

      final logs = logger.getRecentLogs();
      // print('Logs after filtering: ${logs.map((e) => "${e.level.name}: ${e.message}").toList()}');
      expect(
        logs.length,
        2,
        reason:
            'Expected 2 logs but got ${logs.length}. Logs: ${logs.map((e) => e.level.name).toList()}',
      );
      expect(logs.any((e) => e.level == LogLevel.warning), true);
      expect(logs.any((e) => e.level == LogLevel.error), true);
    });

    test('Performance tracking logs duration', () {
      logger.setMinLevel(LogLevel.debug);
      logger.clearLogs();

      final sw = logger.startOperation('test-perf');
      logger.endOperation(sw, 'test-perf');

      final logs = logger.getRecentLogs(count: 10);
      // Logs should include: [info] Log buffer cleared, [debug] Starting..., [info] completed.
      final hasEntry = logs.any(
        (e) =>
            e.message.contains('test-perf completed') && e.tag == 'Performance',
      );

      expect(
        hasEntry,
        true,
        reason:
            'Did not find performance log entry. Logs found: ${logs.map((e) => "${e.tag}: ${e.message}").toList()}',
      );

      final perfLog = logs.firstWhere(
        (e) => e.message.contains('test-perf completed'),
      );
      expect(perfLog.duration, isNotNull);
    });

    test('LogEntry toMap contains expected fields', () {
      final entry = LogEntry(
        level: LogLevel.info,
        tag: 'Auth',
        message: 'Login',
        timestamp: DateTime.now(),
        metadata: {'user': '123'},
      );

      final map = entry.toMap();
      expect(map['level'], 'info');
      expect(map['tag'], 'Auth');
      expect(map['metadata']['user'], '123');
    });
  });
}
