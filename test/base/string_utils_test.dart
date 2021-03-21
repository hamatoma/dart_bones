import 'package:dart_bones/dart_bones.dart';
import 'package:test/test.dart';

void main() {
  final logger = MemoryLogger(LEVEL_FINE);
  StringUtils.setLogger(logger);
  group('DateTime', () {
    test('dateAsString', () {
      final date = DateTime(2019, 3, 7, 3, 45, 59);
      var string = StringUtils.dateAsString(date);
      expect('2019.03.07-03:45:59', equals(string));
    });
    test('dateAsString-now', () {
      var string = StringUtils.dateAsString(null);
      expect(
          string,
          matches(
              RegExp(r'2\d\d\d\.[0-1]\d\.[0-3]\d-[0-2]\d:[0-5]\d:[0-5]\d')));
    });
    test('dateAsString-separator-withoutSeconds', () {
      final date = DateTime(1958, 12, 10, 22, 02, 33);
      var string =
          StringUtils.dateAsString(date, separator: ' ', withoutSeconds: true);
      expect('1958.12.10 22:02', equals(string));
    });
    test('dateToString-fix', () {
      final date = DateTime(2019, 3, 7, 3, 45, 59);
      var string = StringUtils.dateToString('%~%Y.%m.%d-%H:%M:%S%', date);
      expect('%~2019.03.07-03:45:59%', equals(string));
    });
    test('dateToString-known date', () {
      final date = DateTime(2019, 3, 7, 3, 45, 59);
      var string = StringUtils.dateToString('%~%Y.%m.%d-%H:%M:%S%', date);
      expect('%~2019.03.07-03:45:59%', equals(string));
      expect(1, 7 ~/ 4);
      expect(
          StringUtils.dateToString('%!', date), equals('2019.03.07-03:45:59'));
      expect(
          StringUtils.dateToString('%i', date), equals('2019-03-07 03:45:59'));
      expect(StringUtils.dateToString('%j', date), equals('066'));
      expect(StringUtils.dateToString('%%', date), equals('%'));
      expect(StringUtils.dateToString('%F', date), equals('2019-03-07'));
      expect(StringUtils.dateToString('%n', date), equals('\n'));
      expect(StringUtils.dateToString('%R', date), equals('03:45'));
      expect(StringUtils.dateToString('%s', date), equals('1551926759'));
      expect(StringUtils.dateToString('%w', date), equals('4'));
      expect(StringUtils.dateToString('%W', DateTime(2016, 11, 5)), equals('44'));
      expect(StringUtils.dateToString('%W', DateTime(2019, 3, 7)), equals('10'));
      expect(StringUtils.dateToString('%W', date), equals('10'));
      expect(StringUtils.dateToString('%W', DateTime(2021, 3, 21)), equals('11'));
    });
    test('dateToString-now', () {
      var string1 = StringUtils.dateToString('%Y.%m.%d-%H:%M:%S');
      var string2 = StringUtils.dateAsString(null);
      expect(string1.substring(0, 10), equals(string2.substring(0, 10)));
    });
    test('stringToDateTime', () {
      final currentYear = DateTime.now().year;
      expect(StringUtils.stringToDateTime('2019.12.03').toIso8601String(),
          equals('2019-12-03T00:00:00.000'));
      expect(StringUtils.stringToDateTime('12.3').toIso8601String(),
          equals('$currentYear-12-03T00:00:00.000'));
      expect(StringUtils.stringToDateTime('2020.1.3-3:4').toIso8601String(),
          equals('2020-01-03T03:04:00.000'));
      expect(StringUtils.stringToDateTime('1.3-12:45:21').toIso8601String(),
          equals('$currentYear-01-03T12:45:21.000'));
    });
    test('stringToDateTime-error', () {
      try {
        StringUtils.stringToDateTime('x');
        expect('ArgumentError', equals(''));
      } on ArgumentError catch (exc) {
        expect(exc.toString(),
            equals('Invalid argument(s): not a date or date time: x'));
      }
    });
  });
  group('xxxOption', () {
    test('boolOption', () {
      expect(StringUtils.boolOption('run-time', 'r', '--run-time'),
          equals(Bool.TRUE));
      expect(StringUtils.boolOption('run-time', 'r', '-r'), equals(Bool.TRUE));
      expect(StringUtils.boolOption('run-time', 'r', '--run-time=false'),
          equals(Bool.FALSE));
      expect(StringUtils.boolOption('run-time', 'r', '--run-time=f'),
          equals(Bool.FALSE));
      expect(StringUtils.boolOption('run-time', 'r', '--run-time=true'),
          equals(Bool.TRUE));
      expect(
          StringUtils.boolOption('run-time', 'r', '--x'), equals(Bool.UNDEF));
    });
    test('boolOption-error', () {
      try {
        StringUtils.boolOption('run-time', 'r', '--run-time=Tr');
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(exc.cause,
            equals('missing <bool> in --run-time=Tr: e.g. "true" or "false"'));
      }
    });
    test('byteOption', () {
      expect(StringUtils.byteOption('max-size', 'm', '-m123'), equals(123));
      expect(StringUtils.byteOption('max-size', 'm', '-m123k'), equals(123000));
      expect(
          StringUtils.byteOption('max-size', 'm', '-m3mbyte'), equals(3000000));
      expect(
          StringUtils.byteOption('max-size', 'm', '-m3G'), equals(3000000000));
      expect(StringUtils.byteOption('max-size', 'm', '-m3TByte'),
          equals(3000000000000));
      expect(StringUtils.byteOption('max-size', 'm', '--max-size=321'),
          equals(321));
      expect(StringUtils.byteOption('max-size', 'm', '--max-size=4ki'),
          equals(4 * 1024));
      expect(StringUtils.byteOption('max-size', 'm', '--max-size=5MiB'),
          equals(5 * 1024 * 1024));
      expect(StringUtils.byteOption('max-size', 'm', '--max-size=6GIBYTE'),
          equals(6 * 1024 * 1024 * 1024));
    });
    test('byteOption-error', () {
      try {
        StringUtils.byteOption('max', 'm', '-mx');
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(
            exc.cause,
            equals(
                'wrong syntax (<count>[<unit>]) in -mx: examples: 1234321 3G 2TByte 200ki 128mbyte'));
      }
      try {
        StringUtils.byteOption('max', 'm', '-m5Mby');
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(
            exc.cause,
            equals(
                'wrong syntax (<count>[<unit>]) in -m5Mby: examples: 1234321 3G 2TByte 200ki 128mbyte'));
      }
      try {
        StringUtils.byteOption('max', 'm', '--max');
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(exc.cause, equals('missing =<count><unit> in --max'));
      }
    });
    test('dateOption', () {
      final currentYear = DateTime.now().year;
      expect(
          StringUtils.dateOption('newer-than', 'n', '-n2020.01.20')
              .toIso8601String(),
          equals('2020-01-20T00:00:00.000'));
      expect(
          StringUtils.dateOption('newer-than', 'n', '--newer-than=01.20-3:44')
              .toIso8601String(),
          equals('$currentYear-01-20T03:44:00.000'));
    });
    test('dateOption-error', () {
      try {
        StringUtils.dateOption('newer-than', 'n', '-n22');
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(exc.cause,
            equals('Invalid argument(s): not a date or date time: 22'));
      }
      try {
        StringUtils.dateOption('max', 'm', '--max');
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(exc.cause, equals('missing =<reg-expr> in --max'));
      }
    });
    test('intOption', () {
      expect(StringUtils.intOption('verbose-level', 'v', '-v3', -1), equals(3));
      expect(
          StringUtils.intOption('verbose-level', 'v', '--verbose-level=2', -1),
          equals(2));
      expect(StringUtils.intOption('verbose-level', 'v', '-x', -1), equals(-1));
    });
    test('intOption-error', () {
      try {
        StringUtils.intOption('verbose-level', 'v', '-vx3', -1);
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(exc.cause, equals('missing <int> in -vx3'));
      }
      try {
        StringUtils.intOption('verbose-level', 'v', '--verbose-level=3x', -1);
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(exc.cause, equals('missing <int> in --verbose-level=3x'));
      }
      try {
        StringUtils.intOption('verbose-level', 'v', '--verbose-level', -1);
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(exc.cause, equals('missing "<int>" in --verbose-level'));
      }
    });
    test('regExpOption', () {
      expect(StringUtils.regExpOption('exclude', 'x', r'-x.*~$||i').toString(),
          equals(r'RegExp: pattern=.*~$ flags=i'));
      expect(
          StringUtils.regExpOption('exclude', 'x', r'--exclude=.*\.log$')
              .toString(),
          equals(r'RegExp: pattern=.*\.log$ flags='));
    });
    test('regExpOption-error', () {
      try {
        StringUtils.regExpOption('exclude', 'x', r'--exclude=(.*\.log');
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(
            exc.cause,
            equals(
                'syntax error (reg. expression) in --exclude=(.*\\.log: FormatException: Unterminated group(.*\\.log'));
      }
      try {
        StringUtils.regExpOption('exclude', 'x', r'--exclude=');
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(exc.cause, equals('missing =<reg-expr> in --exclude='));
      }
    });
    test('patternOption', () {
      expect(
          StringUtils.patternOption('exclude', 'x', r'-x*.log|*.txt||i')
              .toString(),
          equals(r'RegExp: pattern=^(.*\.log|.*\.txt)$ flags=i'));
      expect(
          StringUtils.patternOption('exclude', 'x', r'--exclude=|[a-f].*~$||i')
              .toString(),
          equals(r'RegExp: pattern=[a-f].*~$ flags=i'));
      expect(
          StringUtils.patternOption('exclude', 'x', r'--exclude=|.*\.log$')
              .toString(),
          equals(r'RegExp: pattern=.*\.log$ flags='));
    });
    test('patternOption-error', () {
      try {
        StringUtils.patternOption('exclude', 'x', r'--exclude=(.*\.log');
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(exc.cause,
            startsWith('syntax error (reg. expression) in --exclude='));
      }
      try {
        StringUtils.patternOption('exclude', 'x', r'--exclude=');
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(exc.cause, equals('missing =<pattern> in --exclude='));
      }
      try {
        StringUtils.patternOption('exclude', 'x', r'--exclude=|)');
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(exc.cause, startsWith('syntax error (reg. expression) in '));
      }
    });
    test('stringOption', () {
      expect(StringUtils.stringOption('log-file', 'l', '--log-file=/tmp/x.log'),
          equals('/tmp/x.log'));
      expect(StringUtils.stringOption('log-file', 'l', '-l/tmp/y.log'),
          equals('/tmp/y.log'));
      expect(StringUtils.stringOption('log-file', 'l', '-x'), isNull);
      expect(StringUtils.stringOption('log-file', 'l', '-l'), equals(''));
      expect(
          StringUtils.stringOption('log-file', 'l', '--log-file='), equals(''));
      expect(StringUtils.stringOption('log-file', 'l', '-lx', notEmpty: true),
          equals('x'));
      expect(
          StringUtils.stringOption('log-file', 'l', '--log-file=x',
              notEmpty: true),
          equals('x'));
    });
    test('stringOption-error', () {
      try {
        StringUtils.stringOption('log-file', 'l', '-l', notEmpty: true);
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(exc.cause, equals('<string> may not be empty: -l'));
      }
      try {
        StringUtils.stringOption('log-file', 'l', '--log-file');
        expect('OptionException', equals(''));
      } on OptionException catch (exc) {
        expect(exc.cause, equals('missing =<string> in --log-file'));
      }
    });
  });
  group('convert', () {
    test('globPatternToRegExpression', () {
      expect(StringUtils.globPatternToRegExpression('*.log'),
          equals(r'^.*\.log$'));
      expect(StringUtils.globPatternToRegExpression('*test[0-9]?.log'),
          equals(r'^.*test[0-9].\.log$'));
      expect(StringUtils.globPatternToRegExpression('*.txt|*.doc'),
          equals(r'^(.*\.txt|.*\.doc)$'));
    });
    test('decimalToInt', () {
      var length = <int>[0];
      expect(StringUtils.decimalToInt('x12y', 1), equals(12));
      expect(StringUtils.decimalToInt('x444', 1, length), equals(444));
      expect(length[0], equals(3));
      expect(StringUtils.decimalToInt('x4711', 1, length, 3), equals(47));
      expect(length[0], equals(2));
      expect(StringUtils.decimalToInt('x4711', 2, null, 3), equals(7));
    });
    test('asInt', () {
      expect(StringUtils.asInt('x12y', defaultValue: -1), equals(-1));
      expect(StringUtils.asInt('0'), equals(0));
      expect(StringUtils.asInt('0', defaultValue: -1), equals(0));
      expect(StringUtils.asInt('12345678', defaultValue: -1), equals(12345678));
      expect(StringUtils.asInt('90'), equals(90));
      expect(StringUtils.asInt('+90'), equals(90));
      expect(StringUtils.asInt('-90'), equals(-90));
      expect(StringUtils.asInt('0xabcdef'), equals(0xabcdef));
      expect(StringUtils.asInt('0XABCDEF'), equals(0xabcdef));
      expect(StringUtils.asInt('0X01234'), equals(0X01234));
      expect(StringUtils.asInt('-0X01234'), equals(0X01234));
      expect(StringUtils.asInt('+0X01234'), equals(0X01234));
      expect(StringUtils.asInt('0x56789a'), equals(0x56789a));
      expect(StringUtils.asInt('0o567'), equals(375));
      expect(StringUtils.asInt('0O12345'), equals(5349));
      expect(StringUtils.asInt('-0O12345'), equals(-5349));
      expect(StringUtils.asInt('+0O12345'), equals(5349));
      expect(StringUtils.asInt('', defaultValue: -1), equals(-1));
      expect(StringUtils.asInt(null, defaultValue: -2), equals(-2));
      expect(StringUtils.asInt('0x', defaultValue: -2), equals(-2));
      expect(StringUtils.asInt('0o', defaultValue: -2), equals(-2));
      expect(StringUtils.asInt(' 1 ', defaultValue: -2), equals(-2));
      expect(StringUtils.asInt(' 1', defaultValue: -2), equals(-2));
      expect(StringUtils.asInt('1 ', defaultValue: -2), equals(-2));
    });
    test('asFloat', () {
      expect(StringUtils.asFloat('7'), equals(7.0));
      expect(StringUtils.asFloat('7', defaultValue: -1), equals(7.0));
      expect(StringUtils.asFloat('0.23'), equals(0.23));
      expect(StringUtils.asFloat('-0.23'), equals(-0.23));
      expect(StringUtils.asFloat('+0.23'), equals(0.23));
      expect(StringUtils.asFloat('+0.23E-2'), equals(0.23E-2));
      expect(StringUtils.asFloat('-0.23E+3'), equals(-0.23E+3));
      expect(StringUtils.asFloat('', defaultValue: -99.0), equals(-99.0));
      expect(StringUtils.asFloat(null, defaultValue: -99.0), equals(-99.0));
      expect(StringUtils.asFloat('a', defaultValue: -99.0), equals(-99.0));
    });
    test('decodeUtf8HmDu', () {
      expect(StringUtils.decodeUtf8HmDu('x'), equals('x'));
      expect(
          StringUtils.decodeUtf8HmDu(
              'x12y^C384#^C396#^C39C#^C3A4#^C3B6#^C3BC#^C39F#^E282AC#.Ae.Euro.txt'),
          equals('x12yÄÖÜäöüß€.Ae.Euro.txt'));
    });
    test('limitString', () {
      expect(StringUtils.limitString('abc123', 5), equals('ab...'));
      expect(StringUtils.limitString('abc123', 6), equals('abc123'));
      expect(StringUtils.limitString('abc123', 7), equals('abc123'));
      expect(StringUtils.limitString('abc123', 4), equals('a...'));
      expect(StringUtils.limitString('abc123', 3), equals('abc'));
      expect(StringUtils.limitString('abc123', 2), equals('ab'));
      expect(StringUtils.limitString('abc123', 1), equals('a'));
      expect(StringUtils.limitString('abc123', 0), equals(''));
      expect(
          StringUtils.limitString('abc123', 5, ellipsis: '*'), equals('abc1*'));
      expect(StringUtils.limitString(null, 10), isNull);
    });
    test('stringToEnum', () {
      expect(StringUtils.stringToEnum<BlaBla>('aa', BlaBla.values),
          equals(BlaBla.aa));
      expect(StringUtils.stringToEnum<BlaBla>('bb', BlaBla.values),
          equals(BlaBla.bb));
      expect(StringUtils.stringToEnum<BlaBla>('cc', BlaBla.values),
          equals(BlaBla.cc));
      expect(StringUtils.stringToEnum('', BlaBla.values), isNull);
      expect(StringUtils.stringToEnum('a', BlaBla.values), isNull);
      expect(StringUtils.stringToEnum(null, BlaBla.values), isNull);
    });
    test('enumToString', () {
      expect(StringUtils.enumToString(BlaBla.aa), equals('aa'));
      expect(StringUtils.enumToString(BlaBla.bb), equals('bb'));
      expect(StringUtils.enumToString(BlaBla.cc), equals('cc'));
    });
  });
  group('replace', () {
    test('replacePlaceholders', () {
      final map = {'user': 'adam', 'id': '33'};
      final rexprVariable = RegExp(r'!\{?(\w+)\}?');
      expect(
          StringUtils.replacePlaceholders(
              '!user: id: !{id}', map, rexprVariable),
          equals('adam: id: 33'));
      logger.log('expecting error "unknown plaseholder"...', LEVEL_SUMMERY);
      expect(
          StringUtils.replacePlaceholders(
              '123!user.!{user}: id: !{id}!id.rest', map, rexprVariable),
          equals('123adam.adam: id: 3333.rest'));
      expect(
          StringUtils.replacePlaceholders(
              '123!user.!{user}: id: !{ix}!id.rest', map, rexprVariable),
          equals('123adam.adam: id: !{ix}33.rest'));
    });
  });
  group('query', () {
    test('countChar', () {
      expect(StringUtils.countChar('a+b+c', '+'), equals(2));
    });
  });
}

enum BlaBla { aa, bb, cc }
