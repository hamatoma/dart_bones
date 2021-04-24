import 'dart:io';

import 'package:dart_bones/dart_bones.dart';
import 'package:dart_bones/src/base/crypto_base_engine.dart';

import 'kiss_random.dart';

class CryptoEngine extends CryptoBaseEngine {
  CryptoEngine(
      {BaseRandom? random,
      required BaseLogger logger,
      String? passPhrase,
      bool usePseudoRandomSalt = false})
      : super(
            random: random,
            logger: logger,
            passPhrase: passPhrase,
            usePseudoRandomSalt: usePseudoRandomSalt) {
    if (!usePseudoRandomSalt) {
      trueRandom.setSeed(DateTime.now().toString() +
          Platform.localeName +
          Platform.localHostname +
          Platform.version);
      trueRandom.setResetState();
    }
  }
}
