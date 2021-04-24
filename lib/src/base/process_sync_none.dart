import 'base_logger.dart';

class ProcessSync {
  ProcessSync([BaseLogger? logger]) {
    throw UnimplementedError('ProcessSync()');
  }
  static ProcessSync initialize(BaseLogger logger) {
    throw UnimplementedError('ProcessSync.initialize()');
  }

  String executeAsScript(String commands,
      {String? workingDirectory,
      Map<String, String>? environment,
      String? prefixLogOutput,
      BaseLogger? logger}) {
    throw UnimplementedError('ProcessSync.executeAsScript()');
  }

  String executeToString(String command, List<String>? args,
      {String? input,
      String? workingDirectory,
      Map<String, String>? environment,
      String? prefixLogOutput,
      BaseLogger? logger}) {
    throw UnimplementedError('ProcessSync.executeToString()');
  }
}
