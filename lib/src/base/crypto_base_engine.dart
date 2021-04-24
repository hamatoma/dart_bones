//import 'dart:io';

import 'package:dart_bones/dart_bones.dart';

import 'kiss_random.dart';

class CryptoBaseEngine {
  KissRandom trueRandom = KissRandom(globalLogger);
  BaseRandom random = KissRandom(globalLogger);
  final BaseLogger logger;
  List<int> firstState = <int>[];
  CryptoBaseEngine(
      {BaseRandom? random,
      required this.logger,
      String? passPhrase,
      bool usePseudoRandomSalt = false}) {
    if (random == null && passPhrase == null) {
      logger.error('CryptoEngine(: logger = licence = null');
      passPhrase = 'TopSecret+LostInSpace.4711';
    }
    if (random != null) {
      this.random = random;
    }
    if (passPhrase != null) {
      random?.setSeed(passPhrase);
    }
    firstState = this.random.saveState();
    if (!usePseudoRandomSalt) {
      trueRandom.setSeed(DateTime.now().toString());
      trueRandom.setResetState();
    }
  }

  /// Decrypts the [encryptedText] encrypted by encrypt().
  /// [saltLength]: this is the length of the salt preceding the [encryptedText].
  String decrypt(String encryptedText,
      {int saltLength = 4,
      CharClass charClass = CharClass.chars95,
      String? charSetMembers}) {
    var rc = '';
    final salt = encryptedText.substring(0, saltLength);
    final encryptedText2 = encryptedText.substring(saltLength);
    final currentState = firstState.toList();
    currentState[0] =
        random.maskOperand(random.maskOperand(salt.hashCode) + currentState[0]);
    random.restoreState(currentState);
    charSetMembers ??= BaseRandom.getCharClassMembers(charClass);
    if (charClass == CharClass.chars95 || charClass == CharClass.chars96) {
      // the charset is ordered like ASCII:
      final upperBound = charClass == CharClass.chars95 ? 127 : 128;
      final max = charClass == CharClass.chars95 ? 95 : 96;
      for (var ix = 0; ix < encryptedText2.length; ix++) {
        final code = encryptedText2.codeUnitAt(ix);
        if (code < 32 || code >= upperBound) {
          rc += encryptedText2[ix];
        } else {
          final rand = random.nextInt(max: max);
          final value = 32 + (code - 32 + max - rand) % max;
          rc += String.fromCharCode(value);
        }
      }
    } else {
      // the charset is not ordered like ASCII:
      // charSetMembers cannot be null!
      final membersLength = charSetMembers?.length ?? 1;
      for (var ix = 0; ix < encryptedText2.length; ix++) {
        final index = charSetMembers?.indexOf(encryptedText2[ix]) ?? -1;
        if (index < 0) {
          rc += encryptedText2[ix];
        } else {
          final rand = random.nextInt(max: membersLength);
          final value = (index + membersLength - rand) % membersLength;
          // charSetMembers cannot be null!
          rc += charSetMembers == null ? '' : charSetMembers[value];
        }
      }
    }
    return rc;
  }

  /// Encrypts the [clearText] with a randomly generated salt of the length
  /// [saltLength].
  /// see decrypt() for reverse encryption.
  String encrypt(String clearText,
      {int saltLength = 4,
      CharClass charClass = CharClass.chars95,
      String charSetMembers = ''}) {
    if (charSetMembers.isEmpty) {
      charSetMembers = BaseRandom.getCharClassMembers(charClass) ?? '';
    }
    var rc = saltLength == 0 ? '' : trueRandom.nextString(saltLength);
    final currentState = firstState.toList();
    currentState[0] =
        random.maskOperand(random.maskOperand(rc.hashCode) + currentState[0]);
    random.restoreState(currentState);
    if (charClass == CharClass.chars95 || charClass == CharClass.chars96) {
      // the charset is ordered like ASCII: we can calculate the index
      final upperBound = charClass == CharClass.chars95 ? 127 : 128;
      final max = charClass == CharClass.chars95 ? 95 : 96;
      for (var ix = 0; ix < clearText.length; ix++) {
        final code = clearText.codeUnitAt(ix);
        if (code < 32 || code >= upperBound) {
          rc += clearText[ix];
        } else {
          final rand = random.nextInt(max: max);
          final value = 32 + ((code - 32 + rand) % max);
          rc += String.fromCharCode(value);
        }
      }
    } else {
      // the charset is not ordered like ASCII: we must search the index
      final max = charClass == CharClass.chars95 ? 95 : 96;
      for (var ix = 0; ix < clearText.length; ix++) {
        final index = charSetMembers.indexOf(clearText[ix]);
        if (index < 0) {
          rc += clearText[ix];
        } else {
          final rand = random.nextInt(max: max);
          final value = (index + rand) % max;
          rc += charSetMembers[value];
        }
      }
    }
    return rc;
  }

  /// Sets the random generator to a well known state.
  void reset() => random.reset();
}
