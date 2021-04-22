import 'package:dart_bones/src/base/base_configuration.dart';

import '../../dart_bones.dart';

/// Implements static functions for files and directories in the sync variant.
class Configuration extends BaseConfiguration {
  String? _filename;

  /// Constructor: reads the configuration file.
  /// [directory]: the configuration file will be searched here
  /// [filePrefix]: the filename without extension. The extension will be found automatically
  Configuration(String directory, String filePrefix, BaseLogger logger)
      : super({}, logger);

  /// Constructor with a given filename.
  Configuration.fromFile(this._filename, BaseLogger logger)
      : super({}, logger) {
    logger.log('configuration_none::Configuration.fromFile() used');
  }

  String? get filename => _filename;
}
