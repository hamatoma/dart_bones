import 'package:sprintf/sprintf.dart';

import '../../dart_bones.dart';

class OptionException implements Exception {
  String cause;

  OptionException(this.cause);
}

/// Offers functions missed in String, e.g. some conversions.
/// All methods are static and sync.
class StringUtils {
  static BaseLogger _logger;

  static RegExp _regExpUtfPattern;
  static final regExprDate1 = RegExp(r'^(?:(\d\d\d\d)\.)?(\d\d?)\.(\d\d?)$');
  static final regExprDateTime2 = RegExp(
      r'^(?:(\d\d\d\d)\.)?(\d\d?)\.(\d\d?)-(\d\d?):(\d\d?)(?::(\d+\d))?$');

  // ....a..1........1..a.2.....2..3.....3.4.....4.5.....5b...6.....6b
  static final regExprInt =
      RegExp(r'^[+-]?(?:(?:0[xX]([\da-fA-F]+))|(?:0[oO]([0-7]+))|(\d+))$');

  // ......................................a..b.......1...........1b.c.......2......2c.3...3a
  /// Converts a [text] into an integer.
  /// [defaultValue] is the return value if [text] is not an integer
  static double asFloat(String text, {double defaultValue}) {
    var rc = defaultValue;
    if (text != null && text.isNotEmpty) {
      try {
        rc = double.parse(text);
      } on FormatException {
        // nothing to do
      }
    }
    return rc;
  }

  /// Converts a [text] into an integer.
  /// [defaultValue] is the return value if [text] is not an integer
  static int asInt(String text, {int defaultValue}) {
    var rc = defaultValue;
    if (text != null && text.isNotEmpty) {
      final match = regExprInt.firstMatch(text);
      if (match != null) {
        var negate = text.startsWith('-');
        if (match.groupCount >= 3 && match.group(3) != null) {
          rc = int.parse(match.group(3));
        } else if (match.groupCount >= 2 && match.group(2) != null) {
          rc = int.parse(match.group(2), radix: 8);
        } else {
          rc = int.parse(text);
        }
        if (negate) {
          rc = -rc;
        }
      }
    }
    return rc;
  }

  /// Tests whether the [argument] has the [longName] or the [shortName] and an boolean.
  /// Returns the value of the boolean argument.
  /// Throws OptionException on error.
  /// [longName]: the long name to inspect, e.g. 'max-length'
  /// [shortName]: the short name to inspect, e.g. 'm'
  /// [argument]: argument to inspect, e.g. '--max-length=3'
  static Bool boolOption(String longName, String shortName, String argument) {
    var rc = Bool.UNDEF;
    if (argument == '--$longName') {
      rc = Bool.TRUE;
    } else if (argument.startsWith('--$longName=')) {
      var matcher = RegExp('.*=(t(rue)?|f(alse)?)\$').firstMatch(argument);
      if (matcher == null) {
        throw OptionException(
            'missing <bool> in $argument: e.g. "true" or "false"');
      }
      rc = matcher.group(1).startsWith('t') ? Bool.TRUE : Bool.FALSE;
    } else if (argument == '-$shortName') {
      rc = Bool.TRUE;
    }
    return rc;
  }

  /// Tests whether the [argument] has the [longName] or the [shortName] and byte value given by an int an a unit.
  /// Returns the int value.
  /// Throws OptionException on error.
  /// [longName]: the long name to inspect, e.g. 'max-size'
  /// [shortName]: the short name to inspect, e.g. 'm'
  /// [argument]: argument to inspect, e.g. '--max-size=50G'
  static int byteOption(String longName, String shortName, String argument) {
    int rc;
    String value;
    if (argument == '--$longName') {
      throw OptionException('missing =<count><unit> in $argument');
    } else if (argument.startsWith('--$longName=')) {
      value = argument.substring(longName.length + 3);
    } else if (shortName != null && argument.startsWith('-$shortName')) {
      value = argument.substring(2);
    }
    if (value != null) {
      var matcher = RegExp(r'(\d+)([kmgt]i?)?(b(yte)?)?$', caseSensitive: false)
          .firstMatch(value);
      if (matcher == null) {
        throw OptionException(
            'wrong syntax (<count>[<unit>]) in $argument: examples: 1234321 3G 2TByte 200ki 128mbyte');
      }
      rc = int.parse(matcher.group(1));
      var unit = matcher.group(2)?.toLowerCase();
      if (unit != null && unit != '') {
        var factor = unit.length > 1 && unit[1] == 'i' ? 1024 : 1000;
        switch (unit[0]) {
          case 'k':
            rc *= factor;
            break;
          case 'm':
            rc *= factor * factor;
            break;
          case 'g':
            rc *= factor * factor * factor;
            break;
          case 't':
            rc *= factor * factor * factor * factor;
            break;
        }
      }
    }
    return rc;
  }

  /// Counts the occurrences of a [char] in a [string].
  static int countChar(String string, String char) {
    var rc = 0;
    for (var ix = string.length - 1; ix >= 0; ix--) {
      if (string[ix] == char) {
        rc++;
      }
    }
    return rc;
  }

  /// Returns a standard representation of [date]: YYYY.mm.dd-HH:MM[:SS]
  /// [date] date to convert. If null the current date and time is taken
  /// [withoutSeconds: true: the seconds are not part of the result
  /// [separator]: the string between date and time, default: '-'
  static String dateAsString(DateTime date,
      {bool withoutSeconds = false, String separator = '-'}) {
    date ??= DateTime.now();
    var rc = StringBuffer();
    rc.write(date.year);
    rc.write('.');
    rc.write(sprintf('%02d', [date.month]));
    rc.write('.');
    rc.write(sprintf('%02d', [date.day]));
    rc.write(separator);
    rc.write(sprintf('%02d', [date.hour]));
    rc.write(':');
    rc.write(sprintf('%02d', [date.minute]));
    if (!withoutSeconds) {
      rc.write(':');
      rc.write(sprintf('%02d', [date.second]));
    }
    return rc.toString();
  }

  /// Tests whether the [argument] has the [longName] or the [shortName] and a date (and time).
  /// Returns the DateTime or null.
  /// Throws OptionException on error.
  /// [longName]: the long name to inspect, e.g. 'log-file'
  /// [shortName]: the short name to inspect, e.g. 'l'
  /// [argument]: argument to inspect, e.g. '--exclude-file=.*\.log'
  static DateTime dateOption(
      String longName, String shortName, String argument) {
    DateTime rc;
    String value;
    if (argument == '--$longName') {
      throw OptionException('missing =<reg-expr> in $argument');
    } else if (argument.startsWith('--$longName=')) {
      value = argument.substring(longName.length + 3);
    } else if (shortName != null && argument.startsWith('-$shortName')) {
      value = argument.substring(2);
    }
    if (value != null) {
      try {
        rc = stringToDateTime(value);
      } on ArgumentError catch (exc) {
        throw OptionException(exc.toString());
      }
    }
    return rc;
  }

  /// Converts a date into a string with a given [format] like the unix command date.
  /// [format]: a string with placeholders, e.g. '%Y.%m.%d-%H:%M:%S'
  /// Format placeholders:
  /// '%!': full (same as '%Y.%m.%d-%H:%M:%S')
  /// '%%': '%'
  /// '%d': day (01..31)
  /// '%F': date (same as '%Y-%m-%d')
  /// '%H': hours (00..23)
  /// '%i': iso (same as '%Y-%m-%d %H:%M:%S')
  /// '%j': day of the year: (001..366)
  /// '%M': minutes (00..59)
  /// '%m': month (01..12)
  /// '%n': '\n'
  /// '%R': time (same as '%H:%M')
  /// '%S': seconds (00.59)
  /// '%s': seconds since epoch
  /// '%W': day of the week (0..6) 0 is monday
  /// '%w': week no (01..53)
  /// '%Y': year (e.g. 2021)
  ///
  /// [date]: the date to convert: if null the current date and time is taken
  static String dateToString(String format, [DateTime date]) {
    date ??= DateTime.now();
    var rc = StringBuffer();
    var index = 0;
    final length = format.length;
    while (index < length) {
      final cc = format[index++];
      if (cc != '%') {
        rc.write(cc);
      } else if (index == length) {
        rc.write('%');
      } else {
        final cc2 = format[index++];
        switch (cc2) {
          case 'Y':
            rc.write(date.year);
            break;
          case 'm':
            rc.write(sprintf('%02d', [date.month]));
            break;
          case 'd':
            rc.write(sprintf('%02d', [date.day]));
            break;
          case 'H':
            rc.write(sprintf('%02d', [date.hour]));
            break;
          case 'M':
            rc.write(sprintf('%02d', [date.minute]));
            break;
          case 'S':
            rc.write(sprintf('%02d', [date.second]));
            break;
          case '!':
            rc.write(sprintf('%d.%02d.%02d-%02d:%02d:%02d', [
              date.year,
              date.month,
              date.day,
              date.hour,
              date.minute,
              date.second
            ]));
            break;
          case 'i':
            rc.write(sprintf('%d-%02d-%02d %02d:%02d:%02d', [
              date.year,
              date.month,
              date.day,
              date.hour,
              date.minute,
              date.second
            ]));
            break;
          case 'j':
            final date2 = DateTime(date.year);
            final date3 = DateTime(date.year, date.month, date.day);
            final day = date3.millisecondsSinceEpoch ~/ 86400000;
            final day2 = date2.millisecondsSinceEpoch ~/ 86400000;
            rc.write(sprintf('%03d', [1 + day - day2]));
            break;
          case '%':
            rc.write('%');
            break;
          case 'F':
            rc.write(
                sprintf('%d-%02d-%02d', [date.year, date.month, date.day]));
            break;
          case 'n':
            rc.write('\n');
            break;
          case 'R':
            rc.write(sprintf('%02d:%02d', [date.hour, date.minute]));
            break;
          case 's':
            rc.write((date.millisecondsSinceEpoch ~/ 1000).toString());
            break;
          case 'w':
            rc.write(date.weekday.toString());
            break;
          case 'W':
            // @see: wikipedia.org/wiki/ISO_week_date#Weeks_per_year
            final year = date.year;
            final date2 = DateTime(year, 1, 1);
            final date3 = DateTime(year, date.month, date.day);
            final dayOfYear = 1 +
                date3.millisecondsSinceEpoch ~/ 86400000 -
                date2.millisecondsSinceEpoch ~/ 86400000;
            int p(int y) => (y + y ~/ 4 - y ~/ 100 + y ~/ 400) % 7;
            int weeks(int y) => 52 + (p(y) == 4 || p(y - 1) == 3 ? 1 : 0);
            final week = (10 + dayOfYear - date3.weekday - 1) ~/ 7;
            final weekNo =
                week < 1 ? weeks(year - 1) : (week > weeks(year) ? 1 : week);
            rc.write(sprintf('%02d', [weekNo]));
            break;
          default:
            rc.write('%');
            rc.write(cc2);
            break;
        }
      }
    }
    return rc.toString();
  }

  /// Returns the int value of a decimal number in a [text] starting at index [start].
  /// [text]: the string to inspect
  /// [length]: OUT: if not null: the count of digits will be stored in length[0]
  /// [last]: if not null: the number detection ends with this index (excluding)
  static int decimalToInt(String text, int start,
      [List<int> length, int last]) {
    var rc = 0;
    last ??= text.length;
    int digit;
    var len = 0;
    while (start < text.length && start < last) {
      if ((digit = text.codeUnitAt(start)) >= 0x30 && digit <= 0x39) {
        rc = rc * 10 + (digit - 0x30);
        ++len;
      } else {
        break;
      }
      ++start;
    }
    if (length != null) {
      length[0] = len;
    }
    return rc;
  }

  /// Convert specially UTF-8 encoded non ASCII characters into real UTF-8.
  /// hmdu is a program which encodes "more byte" UTF-8 characters into the
  /// form "^<hex-digits>#", e.g. "^C384#" for &Auml;
  /// [input]: the string to convert
  /// return: the <input> with decoded UTF-8 ("real UTF-8")
  static String decodeUtf8HmDu(String input) {
    String rc;
    _regExpUtfPattern ??= RegExp(r'\^(([0-9A-F][0-9A-F]){2,4})#');
    for (var item in _regExpUtfPattern.allMatches(input)) {
      rc ??= input;
      final hex = item.group(1);
      var replacement;
      switch (hex) {
        case 'C384':
          replacement = 'Ä';
          break;
        case 'C396':
          replacement = 'Ö';
          break;
        case 'C39C':
          replacement = 'Ü';
          break;
        case 'C3A4':
          replacement = 'ä';
          break;
        case 'C3B6':
          replacement = 'ö';
          break;
        case 'C3BC':
          replacement = 'ü';
          break;
        case 'C39F':
          replacement = 'ß';
          break;
        case 'E282AC':
          replacement = '€';
          break;
        default:
          break;
      }
      if (replacement != null) {
        rc = rc.replaceAll(item.group(0), replacement);
      }
    }
    return rc ?? input;
  }

  /// Converts an [enumValue] to a string.
  static String enumToString(Object enumValue) =>
      enumValue.toString().split('.').last;

  /// Converts a glob [pattern] to a regular expression string.
  /// [pattern]: a string with wildcards '*' and '?' and char classes, e.g. "[a-z0-9\]"
  static String globPatternToRegExpression(String pattern) {
    // mask all meta characters:
    var rc = pattern.replaceAll(r'\', r'\\');
    rc = pattern.replaceAllMapped(RegExp(r'[.+{}]'), (match) {
      return r'\' + match.group(0);
    });
    rc = rc.replaceAll('?', '.').replaceAll('*', '.*');
    if (!pattern.endsWith('*')) {
      if (pattern.contains('|')) {
        rc = '($rc)\$';
      } else {
        rc += r'$';
      }
    }
    rc = '^' + rc;
    return rc;
  }

  /// Tests whether the [argument] has the [longName] or the [shortName] and an integer.
  /// Returns the value of the int argument or the [defaultValue]
  /// Throws OptionException on error.
  /// [longName]: the long name to inspect, e.g. 'max-length'
  /// [shortName]: the short name to inspect, e.g. 'm'
  /// [argument]: argument to inspect, e.g. '--max-length=3'
  /// [defaultValue]: if the arguments does not match: this value is returned
  static int intOption(
      String longName, String shortName, String argument, int defaultValue) {
    var rc = defaultValue;
    if (argument == '--$longName') {
      throw OptionException('missing "<int>" in $argument');
    } else if (argument.startsWith('--$longName=')) {
      var matcher = RegExp(r'=(\d+)$').firstMatch(argument);
      if (matcher == null) {
        throw OptionException('missing <int> in $argument');
      }
      rc = int.parse(matcher.group(1));
    } else if (shortName != null && argument.startsWith('-$shortName')) {
      var matcher = RegExp('^-$shortName(\\d+)\$').firstMatch(argument);
      if (matcher == null) {
        throw OptionException('missing <int> in $argument');
      }
      rc = int.parse(matcher.group(1));
    }
    return rc;
  }

  /// Returns the length limited string.
  /// [string] the string to convert, e.g. "abc123"
  /// [maxSize]: the maximum length, e.g. 5
  /// [ellipsis]: null or a suffix which signals the cut of the [string]
  /// return [string] (if enough space or null) or the limited string, e.g. "ab..."
  static String limitString(String string, maxSize, {String ellipsis = '...'}) {
    String rc;
    maxSize ??= 80;
    if (string != null && string.length > maxSize) {
      ellipsis ??= '';
      if (maxSize < ellipsis.length + 1) {
        rc = string.substring(0, maxSize);
      } else {
        rc = string.substring(0, maxSize - ellipsis.length) + ellipsis;
      }
    }
    rc ??= string;
    return rc;
  }

  /// Tests whether the [argument] has the [longName] or the [shortName] and a pattern.
  /// A pattern is a glob expression (wildcards: '*' and '?) or a regular expression
  /// (if starting with '|').
  /// Returns the RegExp or null.
  /// Throws OptionException on error.
  /// [longName]: the long name to inspect, e.g. 'log-file'
  /// [shortName]: the short name to inspect, e.g. 'l'
  /// [argument]: argument to inspect, e.g. '--exclude-file=*.log'
  static RegExp patternOption(
      String longName, String shortName, String argument) {
    RegExp rc;
    String pattern;
    if (argument == '--$longName' || argument == '--$longName=') {
      throw OptionException('missing =<pattern> in $argument');
    } else if (argument.startsWith('--$longName=')) {
      pattern = argument.substring(longName.length + 3);
    } else if (shortName != null && argument.startsWith('-$shortName')) {
      pattern = argument.substring(2);
    }
    if (pattern != null) {
      var caseSensitive = true;
      if (pattern.endsWith('||i')) {
        caseSensitive = false;
        pattern = pattern.substring(0, pattern.length - 3);
      }
      if (pattern.startsWith('|')) {
        pattern = pattern.substring(1);
      } else {
        pattern = globPatternToRegExpression(pattern);
      }
      try {
        rc = RegExp(pattern, caseSensitive: caseSensitive);
      } on Exception catch (exc) {
        throw OptionException(
            'syntax error (reg. expression) in $argument: $exc');
      }
    }
    return rc;
  }

  /// Tests whether the [argument] has the [longName] or the [shortName] and a regular expression.
  /// Returns the RegExp or null.
  /// Throws OptionException on error.
  /// [longName]: the long name to inspect, e.g. 'log-file'
  /// [shortName]: the short name to inspect, e.g. 'l'
  /// [argument]: argument to inspect, e.g. '--exclude-file=.*\.log'
  static RegExp regExpOption(
      String longName, String shortName, String argument) {
    RegExp rc;
    String pattern;
    if (argument == '--$longName' || argument == '--$longName=') {
      throw OptionException('missing =<reg-expr> in $argument');
    } else if (argument.startsWith('--$longName=')) {
      pattern = argument.substring(longName.length + 3);
    } else if (shortName != null && argument.startsWith('-$shortName')) {
      pattern = argument.substring(2);
    }
    if (pattern != null) {
      var caseSensitive = true;
      if (pattern.endsWith('||i')) {
        caseSensitive = false;
        pattern = pattern.substring(0, pattern.length - 3);
      }
      try {
        rc = RegExp(pattern, caseSensitive: caseSensitive);
      } on Exception catch (exc) {
        throw OptionException(
            'syntax error (reg. expression) in $argument: $exc');
      }
    }
    return rc;
  }

  /// Replaces placeholders in a string with values stored in a map.
  /// [input]: the input string
  /// [variables: a map containing (placeholder, value) pairs
  /// [rexprVariable] a regular expression for one variable.
  /// The variable name must be in group(1)
  /// returns: the input string with the replaced placeholders
  static String replacePlaceholders(
      String input, Map<String, String> variables, RegExp rexprVariable) {
    var rc = input;
    for (var matcher in rexprVariable.allMatches(input)) {
      final name = matcher.group(1);
      if (!variables.containsKey(name)) {
        _logger?.error(
            'replaceVariables(): unknown placeholder $name in ${StringUtils.limitString(input, 40)}');
      } else {
        rc = rc.replaceAll(matcher.group(0), variables[name]);
      }
    }
    return rc;
  }

  static void setLogger(BaseLogger logger) => _logger = logger;

  /// Tests whether the [argument] has the [longName] or the [shortName] and a string.
  /// Returns the value of the string argument or null.
  /// Throws OptionException on error.
  /// [longName]: the long name to inspect, e.g. 'log-file'
  /// [shortName]: the short name to inspect, e.g. 'l'
  /// [argument]: argument to inspect, e.g. '--log-file=app.log'
  /// [notEmpty]: true: the string may not be empty
  static String stringOption(String longName, String shortName, String argument,
      {bool notEmpty = false}) {
    String rc;
    if (argument == '--$longName') {
      throw OptionException('missing =<string> in $argument');
    } else if (argument.startsWith('--$longName=')) {
      rc = argument.substring(longName.length + 3);
    } else if (shortName != null && argument.startsWith('-$shortName')) {
      rc = argument.substring(2);
    }
    if (rc == '' && notEmpty) {
      throw OptionException('<string> may not be empty: $argument');
    }
    return rc;
  }

  /// Converts the string [dateString] into a DateTime instance.
  /// Throws ArgumentsError on syntax error(s).
  static DateTime stringToDateTime(String dateString) {
    RegExpMatch matcher;
    int year, month, day;
    var minute = 0, hour = 0, second = 0;
    if (!dateString.contains('-')) {
      matcher = regExprDate1.firstMatch(dateString);
    } else {
      matcher = regExprDateTime2.firstMatch(dateString);
      if (matcher != null) {
        hour = int.parse(matcher.group(4));
        minute = int.parse(matcher.group(5));
        if (matcher.group(6) != null) {
          second = int.parse(matcher.group(6));
        }
      }
    }
    if (matcher == null) {
      throw ArgumentError('not a date or date time: $dateString');
    }
    final val = matcher.group(1);
    year = val == null || val == ''
        ? DateTime.now().year
        : int.parse(matcher.group(1));
    month = int.parse(matcher.group(2));
    day = int.parse(matcher.group(3));
    var rc = DateTime(year, month, day, hour, minute, second);
    return rc;
  }

  /// Converts a [text] into an enum value.
  /// Returns null if [text] is not valid.
  static T stringToEnum<T>(String text, List<T> values) {
    T rc;
    if (text != null && text.isNotEmpty) {
      final suffix = '.' + text;
      rc = values.firstWhere((e) => e.toString().endsWith(suffix),
          orElse: () => null);
    }
    return rc;
  }
}
