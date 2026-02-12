import 'package:flutter_test/flutter_test.dart';
import 'package:checklist_app/services/logger_service.dart';

void main() {
  test('Minimal Logger Test', () {
    final logger = LoggerService();
    logger.clearLogs();
    logger.setMinLevel(LogLevel.debug);

    logger.info('TEST', 'Msg 1');
    final logs = logger.getRecentLogs();

    expect(logs.length, 1, reason: 'Log buffer should have 1 entry');
    expect(logs.first.tag, 'TEST');
  });

  test('Minimal Performance Test', () {
    final logger = LoggerService();
    logger.clearLogs();
    logger.setMinLevel(LogLevel.debug);

    final sw = logger.startOperation('op');
    logger.endOperation(sw, 'op');

    final logs = logger.getRecentLogs();
    // startOperation logs: debug Performance Starting: op
    // endOperation logs: info Performance op completed

    expect(
      logs.any((e) => e.message.contains('op completed')),
      true,
      reason:
          'Should contain end log. Logs: ${logs.map((e) => "${e.level.name}: ${e.message}").toList()}',
    );
  });
}
