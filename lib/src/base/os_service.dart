import 'dart:io';

import 'package:dart_bones/dart_bones.dart';
import 'package:meta/meta.dart';

import 'base_logger.dart';
import 'process_sync.dart';

/// Holds the information about the current user.
class OsService {
  final BaseLogger logger;
  final UserInfo userInfo = UserInfo();
  OsService(this.logger);

  /// Tests whether a [group] exists.
  bool groupExists(String group) {
    final lines = FileSync.fileAsList('/etc/group');
    final pattern = '$group:';
    final rc = lines.firstWhere((element) => element.startsWith(pattern),
            orElse: () => null) !=
        null;
    return rc;
  }

  /// Returns the group id of an [group] or null.
  int groupId(String group) {
    final lines = FileSync.fileAsList('/etc/group');
    final pattern = '$group:';
    final line = lines.firstWhere((element) => element.startsWith(pattern),
        orElse: () => null);
    final rc = line == null ? null : int.parse(line.split(':')[2]);
    return rc;
  }

  /// Installs an application named [appName].
  /// [configurationFile] is the name of the configuration file to create.
  /// [configurationContent] is a text to write into [configurationFile].
  /// If [configurationContent] is null [configurationFile] is not written.
  /// [targetExecutable] is the directory to store the executable.
  void install(String appName,
      {String configurationFile,
      String configurationContent,
      String targetExecutable = '/usr/local/bin'}) {
    if (!userInfo.isRoot) {
      logger.error('Be root');
    } else {
      configurationFile ??= '/etc/$appName/$appName.yaml';
      if (configurationContent != null) {
        FileSync.ensureDirectory(FileSync.parentOf(configurationFile));
        logger.log('= writing configuration to $configurationFile');
        FileSync.toFile(configurationFile, configurationContent);
      }
      final executable = Platform.script.toFilePath();
      if (executable != null) {
        final file = File(executable);
        if (!file.existsSync()) {
          logger.error('cannot access executable $executable');
        } else {
          logger.log('= $executable -> $targetExecutable');
          file.copy(FileSync.joinPaths(
              targetExecutable, FileSync.nodeOf(executable)));
        }
      }
    }
  }

  /// Creates the file controlling a systemd service.
  /// [serviceName]: used for syslog and environment file.
  /// [starter]: name of the starter with path, e.g. '/usr/local/bin/monitor'.
  /// [user]: the service is started with this user.
  /// [group]: the service is started with this group.
  /// [description]: this string is showed when the status is requested.
  /// [workingDirectory]: the service process starts with that.
  /// [startAtOnce]: true: the service is started at once, false: the service
  /// must be started manually.
  void installService(String serviceName,
      {@required String starter,
      String user,
      String group,
      String description,
      String workingDirectory,
      bool startAtOnce = true}) {
    final userInfo = UserInfo();
    if (!userInfo.isRoot) {
      logger.error('Be root');
    } else if (workingDirectory != null &&
        !workingDirectory.startsWith(Platform.pathSeparator)) {
      logger.error('working directory is not absolute: $workingDirectory');
    } else if (!starter.startsWith(Platform.pathSeparator)) {
      logger.error('starter executable is not absolute: $starter');
    } else if (!File(starter).existsSync()) {
      logger.error('starter executable does not exist: $starter');
    } else {
      final systemDPath = '/etc/systemd/system';
      final systemDFile =
          FileSync.joinPaths(systemDPath, '$serviceName.service');
      user ??= serviceName;
      group ??= user;
      description ??= 'A daemon to service $serviceName';
      workingDirectory ??= '/etc/$serviceName';
      final script = '''[Unit]
Description=$description.
After=syslog.target
[Service]
Type=simple
User=$user
Group=$user
WorkingDirectory=$workingDirectory
#EnvironmentFile=-$workingDirectory/$serviceName.env
ExecStart=$starter daemon $serviceName $user
ExecReload=$starter reload $serviceName $user
SyslogIdentifier=$serviceName
StandardOutput=syslog
StandardError=syslog
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
''';
      logger.log('= installing $systemDFile');
      FileSync.toFile(systemDFile, script);
      if (!userExists(user)) {
        final args = <String>['--no-create-home'];
        if (user != group) {
          args.add('--no-user-group');
        }
        args.add(user);
        logger.log('= creating user $user ' +
            ProcessSync.executeToString('/usr/sbin/useradd', args).trim());
      }
      if (!groupExists(group)) {
        logger.log('= creating group $group ' +
            ProcessSync.executeToString('/usr/sbin/groupadd', [group]).trim());
      }
      logger.log(ProcessSync.executeToString(
          '/bin/systemctl', ['enable', serviceName]));
      if (!startAtOnce) {
        logger
            .log('= Please check the configuration and than start the service:'
                'systemctl start $serviceName');
      } else {
        ProcessSync.executeToString('/bin/systemctl', ['start', serviceName]);
        logger.log('= Status $serviceName\n' +
            ProcessSync.executeToString(
                '/bin/systemctl', ['status', serviceName]));
      }
    }
  }

  void uninstallService(String serviceName, {String user, String group}) {
    final userInfo = UserInfo();
    if (!userInfo.isRoot) {
      logger.error('Be root');
    } else {
      logger.log('= Disabling and stopping the service $serviceName');
      logger.log(ProcessSync.executeToString(
          '/bin/systemctl', ['disable', serviceName]));
      logger.log(
          ProcessSync.executeToString('/bin/systemctl', ['stop', serviceName]));
      logger.log(ProcessSync.executeToString(
          '/bin/systemctl', ['status', serviceName]));
      final systemDFile =
          FileSync.joinPaths('/etc/systemd/system', '$serviceName.service');
      final file = File(systemDFile);
      if (file.existsSync()) {
        logger.log('= removing $systemDFile');
        file.deleteSync();
      }
      if (group == serviceName && groupExists(group)) {
        logger.log('= removing group $group ' +
            ProcessSync.executeToString('/usr/sbin/groupdel', [group]));
      }
      if (user == serviceName && userExists(user)) {
        logger.log('= removing user $user ' +
            ProcessSync.executeToString('/usr/sbin/userdel', [user]));
      }
    }
  }

  /// Tests whether a user exists.
  bool userExists(String user) {
    var rc;
    if (Platform.isLinux) {
      final lines = FileSync.fileAsList('/etc/passwd');
      final pattern = '$user:';
      rc = lines.firstWhere((element) => element.startsWith(pattern),
              orElse: () => null) !=
          null;
    }
    return rc;
  }

  /// Returns the user id of an [user] or null.
  int userId(String user) {
    final lines = FileSync.fileAsList('/etc/passwd');
    final pattern = '$user:';
    final line = lines.firstWhere((element) => element.startsWith(pattern),
        orElse: () => null);
    final rc = line == null ? null : int.parse(line.split(':')[2]);
    return rc;
  }
}

/// Holds the information about the current user.
class UserInfo {
  String currentUserName = fromEnv('USER');
  int currentUserId = -1;
  int currentGroupId;
  String currentGroupName;
  String home = fromEnv('HOME');
  UserInfo() {
    if (Platform.isLinux) {
      final info = ProcessSync.executeToString('/usr/bin/id', []);
      final matcher =
          RegExp(r'uid=(\d+)\((\w+)\) gid=(\d+)\((\w+)').firstMatch(info);
      if (matcher != null) {
        currentUserId = int.parse(matcher.group(1));
        currentUserName = matcher.group(2);
        currentGroupId = int.parse(matcher.group(3));
        currentGroupName = matcher.group(4);
      }
    }
  }
  bool get isRoot =>
      currentUserId < 0 ? currentUserName == 'root' : currentUserId == 0;

  /// Gets the value of a variable named [name] from the environment or null.
  static String fromEnv(String name) {
    var rc = Platform.environment.containsKey(name)
        ? Platform.environment[name]
        : null;
    return rc;
  }
}
