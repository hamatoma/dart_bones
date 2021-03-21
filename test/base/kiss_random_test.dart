import 'dart:io';
import 'package:dart_bones/dart_bones.dart';
import 'package:dart_bones/src/base/kiss_random.dart';
import 'package:test/test.dart';

void main() {
  final logger = MemoryLogger(LEVEL_FINE);
  test('nextInt', () {
    final random = KissRandom(logger);
    for (var no = 1; no < 100000; no++) {
      final value = random.nextInt(max: no);
      expect(value, lessThan(no));
    }
    final found = <int, int>{};
    for (var no = 1; no < 1000000; no++) {
      final value = random.nextInt();
      found[value] = 1;
    }
    print('distinct: ${found.length} of 100000, ${found.length / 10000.0}%');
  });
  test('nextDouble', () {
    final random = KissRandom(logger);
    for (var no = 1; no < 100000; no++) {
      expect(random.nextDouble(), lessThan(1.0));
    }
  });
  test('nextString', () {
    final random = KissRandom(logger);
    for (var length = 4; length < 12; length++) {
      print(random.nextString(length));
    }
    for (var ix = 0; ix < 30; ix++) {
      print(random.nextString(80, CharClass.upperCases));
    }
    print('=');
    for (var ix = 0; ix < 30; ix++) {
      print(random.nextString(80, CharClass.decimals));
    }
  });
  test('char classes', () {
    final random = KissRandom(logger);
    void testOne(CharClass charClass) {
      String source;
      random.reset();
      for (var length = 4; length < 12; length++) {
        source = random.nextString(length, charClass);
        if (notInCharClass(charClass, source) != null) {
          expect(notInCharClass(charClass, source), isNull);
        }
      }
    }

    for (var x in CharClass.values) {
      if (x != CharClass.custom) {
        testOne(x);
      }
    }
  });
  test('save/restore', () {
    final random = KissRandom(logger);
    random.setSeed(DateTime.now().toString());
    random.setResetState();
    for (var ix = 0; ix < 10000; ix++) {
      random.next();
    }
    final first = random.nextString(40, CharClass.hexadecimals);
    random.reset();
    for (var ix = 0; ix < 10000; ix++) {
      random.next();
    }
    final second = random.nextString(40, CharClass.hexadecimals);
    expect(first, equals(second));
    print('$first = $second');
  });
  test('bytes', () {
    const count = 1 * 1000 * 1000;
    final fn = FileSync.tempFile('random.data');
    final random = KissRandom(logger);
    final file = File(fn);
    final fp = file.openSync(mode: FileMode.writeOnly);
    final bytes = random.byteList(count * 4);
    fp.writeFromSync(bytes);
    fp.close();
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), equals(count * 4));
    print('$fn exists');
  });
}
