import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as package_path;

import 'base_configuration.dart';
import 'base_logger.dart';
import 'file_sync_io.dart';

/// Implements static functions for files and directories in the sync variant.
class Configuration extends BaseConfiguration {
  String? _filename;
  final _fileSync = FileSync();

  /// Constructor: reads the configuration file.
  /// [directory]: the configuration file will be searched here
  /// [filePrefix]: the filename without extension. The extension will be found automatically
  Configuration(String directory, String filePrefix, BaseLogger logger)
      : super({}, logger) {
    final prefix = package_path.join(
        directory,
        filePrefix.endsWith('.yaml')
            ? filePrefix.substring(0, filePrefix.length - 5)
            : filePrefix);
    final filename = prefix + '.yaml';
    if (_fileSync.isFile(filename)) {
      _filename = filename;
      final content = _fileSync.fileAsString(filename);
      yamlMap = loadYaml(content);
    } else {
      logger.error('configuration file not found: $prefix.*');
      yamlMap = {};
    }
  }

  /// Constructor with a given or empty [map].
  Configuration.constructed(BaseLogger logger,
      {required Map<String, dynamic> map})
      : super(map, logger);

  /// Constructor with a given filename.
  Configuration.fromFile(String filename, BaseLogger logger)
      : super(fetchYamlMapFromFile(filename, logger), logger) {
    _filename = filename;
  }

  String? get filename => _filename;

  /// Reads the content of a file named [filename] and returns the YamlMap instance.
  static Map fetchYamlMapFromFile(String filename, BaseLogger logger) {
    var map;
    var fileSync = FileSync();
    if (!fileSync.isFile(filename)) {
      logger.error('configuration file not found: $filename');
      map = {};
    } else {
      final content = fileSync.fileAsString(filename);
      if (content.isEmpty) {
        logger.error('empty yaml file: $filename');
        map = {};
      } else {
        map = loadYaml(content);
      }
    }
    return map;
  }
}
