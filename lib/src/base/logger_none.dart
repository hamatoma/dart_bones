import '../../dart_bones.dart';

class Logger extends BaseLogger {
  final String _filename;
  Logger(this._filename, [int logLevel = 1]) : super(logLevel);

  /// Getter of [_filename].
  String filename() => _filename;

  @override
  bool log(String message, [int level = 1]) {
    super.log(message, level);
    logToFile(message);
    return true;
  }

  /// Writes a string into the logfile.
  /// [message] the line to write
  void logToFile(String message) {
    // we cannot write because dart.io is not available
  }
}
