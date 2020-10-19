import '../../dart_bones.dart';

/// Implements a logger which logs to stdout and stores the messages.
class MemoryLogger extends BaseLogger {
  final _messages = <String>[];
  int _maxMessages = 1000;

  MemoryLogger([int logLevel = 1]) : super(logLevel);

  /// getter of [_messages]
  List<String> get messages => _messages;

  /// Removes all entries of [_messages]
  void clear() {
    clearErrors();
    _messages.clear();
  }

  /// Returns whether a given [pattern] is a part of the strings in [_messages].
  /// [pattern]: the string to search
  bool contains(String pattern) {
    var rc = false;
    for (var line in _messages) {
      if (line.contains(pattern)) {
        rc = true;
        break;
      }
    }
    return rc;
  }

  @override
  bool log(String message, [int level = 1]) {
    super.log(message, level);
    if (_maxMessages > 0 && _messages.length >= _maxMessages) {
      _messages.removeAt(0);
    }
    _messages.add(message);
    return true;
  }

  /// Returns whether a given [regExpr] is a part of the strings in [_messages].
  /// [regExpr]: the regular expression to search
  bool matches(String regExpr) {
    var rc = false;
    var regExp = RegExp(regExpr);
    for (var line in _messages) {
      if (regExp.hasMatch(line)) {
        rc = true;
        break;
      }
    }
    return rc;
  }

  /// setter of [_maxMessages]
  void setMaxMessages(int max) => _maxMessages = max;
}
