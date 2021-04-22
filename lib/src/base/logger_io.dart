//import 'package:dart_bones/src/base/base_logger.dart';
import 'dart:io';

import '../../dart_bones.dart';
import 'string_utils.dart' as string_utils;

class Logger extends BaseLogger {
  String _filename;
  File _file = File('');

  Logger(this._filename, [int logLevel = 1]) : super(logLevel) {
    _filename = filename;
    _file = File(filename);
  }

  String get filename => _filename;

  @override
  bool log(String message, [int level = 1]) {
    super.log(message, level);
    logToFile(message);
    return true;
  }

  /// Writes a string into the logfile.
  /// [message] the line to write
  void logToFile(String message) {
    final date = string_utils.dateToString('%!');
    _file.writeAsStringSync('$date $message\n',
        flush: true, mode: FileMode.writeOnlyAppend);
  }
}
