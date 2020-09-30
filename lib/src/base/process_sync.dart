import 'dart:io';

import 'package:dart_bones/dart_bones.dart';
class ProcessSync {
  static BaseLogger _logger;

  /// Executes some [commands] given as lines of a string as shell script.
  /// Creates a shell script with the [commands] and executes this script.
  /// [commands]: one or more external program calls, separated by '\n'
  /// [workingDirectory]: null or the working directory while processing the [commands]
  /// [environment]: null: use the environment of the runtime. Otherwise the environment of the [commands]
  /// [prefixLogOutput]: if not null the output of the script is logged including of this prefix
  /// [logger] if null the static logger [_logger] will be used
  static String executeAsScript(String commands,
      {String workingDirectory,
      Map<String, String> environment,
      String prefixLogOutput,
      BaseLogger logger}) {
    final fnScript = FileSync.tempFile('.script*', extension: '.sh');
    final currentLogger = logger ?? _logger;
    var rc = '';
    currentLogger?.log('executing $fnScript', LEVEL_DETAIL);
    currentLogger?.log(commands, LEVEL_FINE);
    FileSync.toFile(fnScript, '#! /bin/bash\n$commands\n');
    FileSync.chmod(fnScript, 448 /*0700*/);
    var processResult = Process.runSync('/bin/bash', ['-c', fnScript],
        workingDirectory: workingDirectory, environment: environment);
    if (processResult.stderr is String && processResult.stderr.length > 2) {
      currentLogger?.error(processResult.stderr);
    }
    if (processResult.stdout is String) {
      rc = processResult.stdout;
    }
    if (prefixLogOutput != null) {
      currentLogger?.log(prefixLogOutput + rc, LEVEL_SUMMERY);
    }
    return rc;
  }

  /// [command]: the name of the program
  /// [args]: null or the program arguments
  /// [input]: null or the input string (written to stdin)
  /// [workingDirectory]: null or the working directory while processing the [command]
  /// [environment]: null: use the environment of the runtime. Otherwise the environment of the [command]
  /// [prefixLogOutput]: if not null the output of the command is logged including of this prefix
  /// [logger] if null the static logger [_logger] will be used
  static String executeToString(String command, List<String> args,
      {String input,
      String workingDirectory,
      Map<String, String> environment,
      String prefixLogOutput,
      BaseLogger logger}) {
    environment ??= Platform.environment;
    args ??= [];
    var rc = '';
    final currentLogger = logger ?? _logger;
    ProcessResult processResult;
    final argString =
        args == null || args.isEmpty ? '' : " '" + args.join("' '") + "'";
    if (input == null) {
      currentLogger?.log('executing $command $argString', LEVEL_DETAIL);
      processResult = Process.runSync(command, args,
          workingDirectory: workingDirectory, environment: environment);
    } else {
      final fnInput = FileSync.tempFile('.exec.input*');
      FileSync.toFile(fnInput, input);
      final cmd = '''"#! /bin/sh
cat < $fnInput | $command$argString
''';
      currentLogger?.log('executing $cmd', LEVEL_DETAIL);
      processResult = Process.runSync(command, args,
          workingDirectory: workingDirectory,
          environment: environment,
          runInShell: true);
    }
    if (processResult.stderr is String && processResult.stderr.length > 2) {
      currentLogger?.error(processResult.stderr);
    }
    if (processResult.stdout is String) {
      rc = processResult.stdout;
    }
    if (prefixLogOutput != null) {
      currentLogger?.log(prefixLogOutput + rc, LEVEL_SUMMERY);
    }
    return rc;
  }

  /// Sets the logger [_logger].
  static void setLogger(BaseLogger logger) => _logger = logger;
}
