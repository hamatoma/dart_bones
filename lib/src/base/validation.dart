/// Offers functions testing some things like phone numbers.
/// All methods are static and sync.
class Validation {
  static final regExprPhoneNumber = RegExp(r'^[0+][0-9- ]+$');

  // @see https://html.spec.whatwg.org/multipage/input.html#valid-e-mail-address
  static final regExprEMail = RegExp(r'''^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+'''
      r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$');
  static final regExprNat = RegExp(r'^(\d+|0[xX][\da-fA-F]+|0[oO][0-7]+)$');
  static final regExprInt =
      RegExp(r'^[+-]?(?:0[xX][0-9a-fA-F]+|0[oO][0-7]+|\d+)$');

  //RegExp(r'^(?:\d+)$');
  static final regExprBool =
      RegExp(r'^(true|false|yes|no|t|f)$', caseSensitive: false);

  /// Tests whether [text] is a valid boolean value.
  /// Allowed: 'true', 'false', 'yes', 'no' 't', 'f' (case insensitive)
  static bool isBool(String text) {
    var rc = false;
    if (text.isNotEmpty) {
      rc = regExprBool.firstMatch(text) != null;
    }
    return rc;
  }

  /// Tests whether [text] is a valid email address.
  static bool isEmail(String text) {
    var rc = false;
    if (text.isNotEmpty) {
      rc = regExprEMail.firstMatch(text) != null;
    }
    return rc;
  }

  /// Tests whether [text] is a valid integer.
  static bool isFloat(String text) {
    var rc = false;
    if (text.isNotEmpty) {
      try {
        double.parse(text);
        rc = true;
      } on FormatException {
        // nothing to do
      }
    }
    return rc;
  }

  /// Tests whether [text] is a valid integer.
  static bool isInt(String text) {
    var rc = false;
    if (text.isNotEmpty) {
      rc = regExprInt.firstMatch(text) != null;
    }
    return rc;
  }

  /// Tests whether [text] is a valid integer.
  static bool isNat(String text) {
    var rc = false;
    if (text.isNotEmpty) {
      rc = regExprNat.firstMatch(text) != null;
    }
    return rc;
  }

  /// Tests whether [text] is a valid phone number.
  static bool isPhoneNumber(String text) {
    var rc = false;
    if (text.isNotEmpty) {
      rc = regExprPhoneNumber.firstMatch(text) != null;
    }
    return rc;
  }
}
