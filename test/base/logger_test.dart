import 'package:dart_bones/dart_bones.dart';
import 'package:test/test.dart';
import 'package:dart_bones/src/base/logger_io.dart' as logger_io;

void main() {
  final stdLogger = MemoryLogger(LEVEL_FINE);
  final fileSync = FileSync.initialize(stdLogger);
  group('Basics', () {
    test('Logger', () {
      final fn = fileSync.tempFile('test.log', subDirs: 'unittest');
      fileSync.ensureDoesNotExist(fn);
      final logger = logger_io.Logger(fn);
      logger.log('first1');
      logger.error('error1');
      final current = fileSync.fileAsString(fn);
      expect(current, contains('first'));
      expect(current, contains('+++ error1'));
      expect(fn, equals(logger.filename));
      logger.clearErrors();
    });
  });
  group('BaseLogger', () {
    test('Logger', () {
      final logger = BaseLogger(1);
      logger.setMaxErrors(1);
      logger.error('error1');
      expect(logger.errors.length, equals(1));
      logger.error('error2');
      expect(logger.errors.length, equals(1));
      logger.clearErrors();
      expect(logger.errors.length, equals(0));
    });

  });
  group('MemoryLogger', () {
    test('maxMessages', () {
      final logger = MemoryLogger(0);
      logger.setMaxMessages(2);
      logger.log('will be forgotten');
      logger.log('first line');
      logger.error('seccond line');
      expect(logger.contains('forgotten'), isFalse);
      expect(logger.contains('first'), isTrue);
      expect(logger.contains('second'), isFalse);
      logger.clear();
      expect(logger.messages.length, equals(0));
    });
    test('contains', () {
      final logger = MemoryLogger(0);
      logger.log('first line');
      expect(logger.contains('first'), isTrue);
      expect(logger.contains('line'), isTrue);
      expect(logger.contains('*'), isFalse);
    });
    test('matches', () {
      final logger = MemoryLogger(0);
      logger.log('first line');
      expect(logger.matches('.*[lL]ine'), isTrue);
      expect(logger.matches('line\$'), isTrue);
      expect(logger.matches('.*[A-Z].*'), isFalse);
    });
  });
}
