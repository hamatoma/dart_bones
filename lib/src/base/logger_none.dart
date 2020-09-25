import 'package:dart_bones/dart_bones.dart';

class Logger extends BaseLogger {
  String _filename;
  Logger(String filename, [int logLevel = 1]) : super(logLevel){
    _filename = filename;
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
   // we cannot write because dart.io is not available
  }
}
