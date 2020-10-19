import 'package:meta/meta.dart';

const LEVEL_DETAIL = 2;
const LEVEL_FINE = 4;
const LEVEL_LOOP = 3;
const LEVEL_SUMMERY = 1;

/// Implements the superclass of loggers.
class BaseLogger {
  @protected
  var countErrors = 0;
  var logLevel = 1;
  List<String> errors = [];
  var _maxErrors = 100;

  /// Constructor.
  /// [logLevel]: the messages will be displayed on stdout only if the current
  /// level is lower or equals to the [logLevel].
  BaseLogger(this.logLevel);

  /// Clears all errors.
  void clearErrors() {
    countErrors = 0;
    errors.clear();
  }

  /// Logs an error message.
  /// [message]: the error message
  /// [stackTrace]: the stack trace (given by exceptions)
  /// return: false (can be used for chaining)
  bool error(String message, {StackTrace stackTrace}) {
    countErrors++;
    if (errors.length >= _maxErrors) {
      errors.removeAt(0);
    }
    errors.add(message);
    var msg = '+++ ' + message;
    if (stackTrace != null) {
      msg += '\n' + stackTrace.toString();
    }
    log(msg, 0);
    return false;
  }

  /// Displays the message if [logLevel] <= [level]
  /// [message]: message to display
  /// [level]: represent the importance of the message
  /// Returns true (for chaining)
  bool log(String message, [int level = LEVEL_SUMMERY]) {
    if (level <= logLevel) {
      print(message);
    }
    return true;
  }

  /// Sets the [_maxErrors] to limit the length of the internal error list.
  void setMaxErrors(int value) => _maxErrors = value;
}
