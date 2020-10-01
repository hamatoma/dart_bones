import 'package:yaml/yaml.dart';

import 'base_configuration.dart';
import 'base_logger.dart';
import 'file_sync_io.dart';

/// Implements static functions for files and directories in the sync variant.
class Configuration extends BaseConfiguration {
  String _filename;

  String get filename => _filename;

  /// Constructor: reads the configuration file.
  /// [directory]: the configuration file will be searched here
  /// [filePrefix]: the filename without extension. The extension will be found automatically
  Configuration(String directory, String filePrefix, BaseLogger logger)
      : super({}, logger) {
    final prefix = FileSync.joinPaths(
        directory,
        filePrefix.endsWith('.yaml')
            ? filePrefix.substring(0, filePrefix.length - 5)
            : filePrefix);
    final filename = prefix + '.yaml';
    if (FileSync.isFile(filename)) {
      _filename = filename;
      final content = FileSync.fileAsString(filename);
      yamlMap = loadYaml(content);
    } else {
      logger.error('configuration file not found: $prefix.*');
      yamlMap = {};
    }
  }

  /// Constructor with a given or empty [map].
  Configuration.constructed(BaseLogger logger, {Map<String, dynamic> map})
      : super(map, logger);

  /// Constructor with a given filename.
  Configuration.fromFile(this._filename, BaseLogger logger)
      : super({}, logger) {
    if (FileSync.isFile(_filename)) {
      final content = FileSync.fileAsString(filename);
      yamlMap = loadYaml(content);
    } else {
      logger.error('configuration file not found: $_filename.*');
      yamlMap = {};
    }
  }
}
