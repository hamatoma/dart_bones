/// Offers functions testing some things like phone numbers.
/// All methods are static and sync.
class Validation {
  static final _regExprPhoneNumber = RegExp(r'^[0+][0-9- ]+$');
  // @see https://html.spec.whatwg.org/multipage/input.html#valid-e-mail-address
  static final _regExprEMail = RegExp(
      r'''^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+'''
      r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$');

  static bool isEmail(String text) {
    final rc = _regExprEMail.firstMatch(text) != null;
    return rc;
  }

  static bool isPhoneNumber(String text) {
    final rc = _regExprPhoneNumber.firstMatch(text) != null;
    return rc;
  }
}
