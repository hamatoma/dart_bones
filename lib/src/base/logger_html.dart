import 'dart:io';

import '../../dart_bones.dart';

class Logger extends BaseLogger {
  String? _filename;
  File? _file;

  Logger(String filename, [int logLevel = 1]) : super(logLevel) {
    _filename = filename;
    _file = File(filename);
  }

  /// Getter of [_filename].
  String? filename() => _filename;

  @override
  bool log(String message, [int level = 1]) {
    super.log(message, level);
    logToFile(message);
    return true;
  }

  /// Writes a string into the logfile.
  /// [message] the line to write
  void logToFile(String message) {
    _file?.writeAsStringSync(message,
        flush: true, mode: FileMode.writeOnlyAppend);
  }
}
