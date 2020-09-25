import 'package:dart_bones/dart_bones.dart';
import 'dart:io';

class Logger extends BaseLogger {
  String _filename;
  File _file;
  Logger(String filename, [int logLevel = 1]) : super(logLevel){
    _filename = filename;
    _file = File(filename);
  }
  /// Getter of [_filename].
  String filename() => _filename;

  @override
  void log(String message, [int level=1]){
    super.log(message, level);
    logToFile(message);
  }
  /// Writes a string into the logfile.
  /// [message] the line to write
  void logToFile(String message){
   _file.writeAsStringSync(message, flush: true, mode: FileMode.writeOnlyAppend);
  }
}
