import 'base_logger.dart';

/// Tests whether all characters of [string] are in the [charClass].
/// Returns null if all characters are in the charClass, otherwise the first
/// index of [string] with a character not in [charClass]
int notInCharClass(CharClass charClass, String string) {
  int rc;
  final members = BaseRandom.getCharClassMembers(charClass);
  for (var ix = 0; ix < string.length; ix++) {
    if (!members.contains(string[ix])) {
      rc = ix;
      break;
    }
  }
  return rc;
}

abstract class BaseRandom {
  static const MaxInt = 0x100000000;
  static var nextId = 0;
  static final decimals = '0123456789';
  static final hexadecimals = '0123456789abcdef';
  static final upperCases = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static final lowerCases = 'abcdefghijklmnopqrstuvwxyz';
  static final letters = upperCases + lowerCases;
  static final words = letters + '_';
  static final alphanumerics = decimals + words;
  static final chars64 = alphanumerics + r'$';
  static final chars95 =
      r''' !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~''';
  static final chars96 = chars95 + String.fromCharCode(127);
  int id;
  final BaseLogger logger;
  List<int> resetState;

  BaseRandom(this.logger) {
    id = ++nextId;
  }

  /// Returns a list of random bytes with a given [length].
  List<int> byteList(int length) {
    final rc = List.filled(length, 0);
    int value;
    for (var ix = length - 1; ix >= 4; ix -= 4) {
      value = next();
      rc[ix] = value & 0xff;
      value >>= 8;
      rc[ix - 1] = value & 0xff;
      value >>= 8;
      rc[ix - 2] = value & 0xff;
      value >>= 8;
      rc[ix - 3] = value & 0xff;
    }
    value = next();
    for (var ix = length >= 4 ? 3 : length - 1; ix >= 0; ix--) {
      rc[ix] = value & 0xff;
      value >>= 8;
    }
    return rc;
  }

  /// Removes the most significant bits from an multiply operand.
  /// Needed on restricted arithmetic.
  int maskFactor(int factor);

  /// Removes the most significant bits from an addition operand.
  /// Needed on restricted arithmetic.
  int maskOperand(int operand);

  /// Calculates the next seed.
  int next();

  /// Returns a random double with 0 <= rc < 1.
  double nextDouble() {
    final rc = next() / 0xfffffffe;
    return rc;
  }

  /// Returns a random integer with 0 <= rc < [max].
  int nextInt({int max = MaxInt, int min = 0}) {
    if (max - min > MaxInt) {
      final message = 'BaseRandom.nextInt(): range to large: $min $max';
      logger.error(message);
      throw FormatException(message);
    }
    final rc = min + next() % (max - min);
    if (logger.logLevel >= LEVEL_DEBUG) {
      logger.log('$id: nextInt($max, $min): $rc');
    }
    return rc;
  }

  /// Returns a random string with a given [length].
  /// [charClass]: defines the characters of the result.
  /// [charList] is null or a string with all allowed characters.
  /// @throws FormatException if [charClass] is custom and [charList] is null.
  String nextString(int length,
      [CharClass charClass = CharClass.chars96, String charList]) {
    var rc = '';
    charList ??= getCharClassMembers(charClass);
    if (charList == null) {
      final message = 'nextString(): missing charList';
      logger.error(message);
      throw FormatException(message);
    }
    while (length-- > 0) {
      rc += charList[next() % charList.length];
    }
    if (logger.logLevel >= LEVEL_DEBUG) {
      logger.log('$id: nextString: $rc');
    }
    return rc;
  }

  /// Sets the state to a well known state: the start state or the state of the
  /// last call of setStart()
  void reset() {
    restoreState(resetState);
  }

  void restoreState(List<int> list);

  List<int> saveState();

  /// Sets the state used in reset().
  /// Must be called in the constructor of each overloading class.
  void setResetState() {
    resetState = saveState();
  }

  void setSeed(String passphrase);

  static String getCharClassMembers(CharClass charClass) {
    String charList;
    switch (charClass) {
      case CharClass.decimals:
        charList = decimals;
        break;
      case CharClass.hexadecimals:
        charList = hexadecimals;
        break;
      case CharClass.upperCases:
        charList = upperCases;
        break;
      case CharClass.lowerCases:
        charList = lowerCases;
        break;
      case CharClass.letters:
        charList = letters;
        break;
      case CharClass.words:
        charList = words;
        break;
      case CharClass.alphanumerics:
        charList = alphanumerics;
        break;
      case CharClass.chars64:
        charList = chars64;
        break;
      case CharClass.chars95:
        charList = chars95;
        break;
      case CharClass.chars96:
        charList = chars96;
        break;
      default:
        break;
    }
    return charList;
  }
}

enum CharClass {
  custom,
  decimals,
  hexadecimals,
  upperCases,
  lowerCases,
  letters,
  words,
  alphanumerics,
  chars64,
  chars95,
  chars96
}

/// A pseudo random generator from George Marsaglia.
/// https://de.wikipedia.org/wiki/KISS_(Zufallszahlengenerator)
/// The algorithm is modified to support JavaScript ("Web") with
/// float arithmetic only:
/// * each state calculation is restricted to a 32 bit value.
/// * multiplication is restricted to 52 Bit (mantissa in IEEE-754)
/// * each multiplication operand is restricted to 26 bit.
/// Period length: 2**124 near 2.12E37
/// Small state vector (4 int values)
/// https://github.com/dworthen/prng/blob/master/support/js/Xorshift03.js
class KissRandom extends BaseRandom {
  static const IntMask = 0xffffffff;
  static const FactorMask = 0x3ffffff; // 2**26 - 1
  int addParam = 12345;
  int factorParam = 69069 & FactorMask;
  int factorParam2 = 698769069 & FactorMask;
  int x = 123456789;
  int y = 362436000; // but y != 0 and
  int z = 521288629 & FactorMask; // z,c not both 0
  int c = 7654321 & FactorMask;

  KissRandom(BaseLogger logger) : super(logger) {
    setResetState();
  }
  @override
  int maskFactor(int factor) {
    return factor & IntMask;
  }

  @override
  int maskOperand(int operand) {
    return operand & FactorMask;
  }

  @override
  int next() {
    // Linear congruence generator:
    x = ((factorParam * x) & IntMask + addParam) & IntMask;

    // Xor shift
    y = (y ^ (y << 13)) & IntMask;
    y = (y ^ (y >> 17)) & IntMask;
    y = (y ^ (y << 5)) & IntMask;

    // Multiply-with-carry: t = 698769069 * z + c; c = high(t); z = low(t);
    // tFirst cannot "overflow" (mantissa remains exact):
    var tFirst = factorParam2 * (z & FactorMask);
    z = ((tFirst & IntMask) + c) & FactorMask;
    c = ((tFirst + c) >> 26) & FactorMask;

    final rc = (x + y + z) & IntMask;
    if (logger.logLevel >= LEVEL_DEBUG) {
      logger.log('$id: next: $rc');
    }
    return rc;
  }

  @override
  void restoreState(List<int> list) {
    x = list[0] & IntMask;
    // y != 0
    y = (list[1] & IntMask);
    if (y == 0) {
      y = 33442211 & IntMask;
    }
    // (z | c) != 0
    z = list[2] & FactorMask;
    c = list[3] & FactorMask;
    if (z == 0 && c == 0) {
      z = 332211 & FactorMask;
    }
    if (logger.logLevel >= LEVEL_DEBUG) {
      logger.log('$id: restoreState: $x $y $z $c');
    }
  }

  @override
  List<int> saveState() {
    final rc = <int>[x, y, z, c];
    return rc;
  }

  @override
  void setSeed(String passphrase) {
    final length = passphrase.length;
    if (length >= 8) {
      var subLength = passphrase.length ~/ 4;
      restoreState([
        passphrase.substring(0, subLength).hashCode,
        passphrase.substring(subLength, 2 * subLength).hashCode,
        passphrase.substring(2 * subLength, 3 * subLength).hashCode,
        passphrase.substring(3 * subLength).hashCode
      ]);
    } else if (length >= 4) {
      restoreState([
        passphrase.hashCode,
        passphrase.substring(1).hashCode,
        passphrase.substring(2).hashCode,
        passphrase.substring(3).hashCode
      ]);
    } else {
      switch (length) {
        case 0:
          restoreState([1, 2, 3, 4]);
          break;
        case 1:
          restoreState([passphrase.hashCode, 12, 123, 0x1234]);
          break;
        case 2:
          restoreState([
            passphrase.hashCode,
            passphrase.substring(1).hashCode,
            123,
            0x1234
          ]);
          break;
        case 3:
          restoreState([
            passphrase.hashCode,
            passphrase.substring(1).hashCode,
            passphrase.substring(2).hashCode,
            0x1234
          ]);
          break;
      }
    }
  }
}
