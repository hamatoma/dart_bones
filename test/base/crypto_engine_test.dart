import 'package:dart_bones/dart_bones.dart';
import 'package:dart_bones/src/base/crypto_engine.dart';
import 'package:dart_bones/src/base/kiss_random.dart';
import 'package:test/test.dart';

void main() {
  BaseLogger logger = MemoryLogger(LEVEL_FINE);
  final engine = CryptoEngine(passPhrase: 'HelloWorld', logger: logger);
  test ('one', (){
    String encrypted, decrypted;

    logger.log('a:', LEVEL_DEBUG);
    encrypted = engine.encrypt('a');
    decrypted = engine.decrypt(encrypted);
    expect(decrypted, 'a');

    logger.log('01:', LEVEL_DEBUG);
    encrypted = engine.encrypt('01');
    decrypted = engine.decrypt(encrypted);
    expect(decrypted, '01');

    logger.log('Honky Tonk Women:', LEVEL_DEBUG);
    encrypted = engine.encrypt('Honky Tonk Women', saltLength: 0);
    decrypted = engine.decrypt(encrypted, saltLength: 0);
    expect(decrypted, 'Honky Tonk Women');
  });
  test('basics', () {
    final encryptedStrings = <String>[];
    for (var ix = 0; ix < 200; ix++) {
      encryptedStrings.add(engine.encrypt(ix.toString()));
    }
    for (var ix = 0; ix < 200; ix++) {
      expect(engine.decrypt(encryptedStrings[ix]), equals(ix.toString()));
    }
  });
  test('mass test', () {
    final random = KissRandom(logger);
    final strings = <String>[];
    final encryptedStrings = <String>[];
    for (var ix = 0; ix < 100000; ix++) {
      final source = random.nextString(random.nextInt(min: 8, max: 80), CharClass.chars64);
      strings.add(source);
      encryptedStrings.add(engine.encrypt(source));
    }
    for (var ix = 0; ix < 100000; ix++) {
      expect(engine.decrypt(encryptedStrings[ix]), equals(strings[ix]));
    }
    print(strings[0] + ' ... ' + strings[strings.length-1]);
    print(encryptedStrings[0] + ' ... ' + encryptedStrings[encryptedStrings.length-1]);
  });
}
