import 'package:dart_bones/dart_bones.dart';

import 'base_logger.dart';

/// Holds the information about the current user.
class OsService {
  OsService(BaseLogger logger) {
    throw UnsupportedError('OsService.uninstallService()');
  }
  void install(String appName,
      {String? configurationFile,
      String? configurationContent,
      String targetExecutable = '/usr/local/bin'}) {
    throw UnsupportedError('OsService.install()');
  }

  void installService(String serviceName,
      {required String starter,
      String? user,
      String? group,
      String? description,
      String? workingDirectory,
      bool startAtOnce = true}) {
    throw UnsupportedError('OsService.installService()');
  }

  void uninstallService(String serviceName, {String? user, String? group}) {
    throw UnsupportedError('OsService.uninstallService()');
  }
}

class UserInfo {
  UserInfo() {
    throw UnsupportedError('UserInfo()');
  }
  bool get isRoot => throw UnsupportedError('UserInfo.isRoot()');

  /// Gets the value of a variable named [name] from the environment or null.
  static String? fromEnv(String name) {
    throw UnsupportedError('UserInfo.fromEnv()');
  }
}
