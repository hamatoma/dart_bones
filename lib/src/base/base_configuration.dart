import 'package:meta/meta.dart';

import 'base_logger.dart';

/// Implements read access to a YAML based configuration content.
/// Only a two levels structure is allowed: simple types in the first level
/// or simple types in a named map. The name of such a map is called "section".
class BaseConfiguration {
  @protected
  Map yamlMap;
  @protected
  BaseLogger logger;

  /// Constructor: reads the configuration file.
  /// [yamlMap] contains the data.
  BaseConfiguration(this.yamlMap, this.logger);

  bool get isEmpty => yamlMap.isEmpty;
  bool get isNotEmpty => yamlMap.isNotEmpty;

  /// Returns a bool value given by [section] and [key].
  /// [key]: the key of the (key value) pair
  /// [section]: if given the (key value) pair is searched in this section
  bool asBool(String key, {String? section}) {
    var rc = false;
    final value = asString(key, section: section);
    if (value == null) {
      final sectionPart = section == null ? '' : ' in ' + section;
      logger.error('missing $key$sectionPart');
    } else {
      rc = value.toLowerCase() == 'true';
    }
    return rc;
  }

  /// Returns a float value given by [section] and [key].
  /// [key]: the key of the (key value) pair
  /// [section]: if given the (key value) pair is searched in this section
  /// [defaultValue]: if the key does not exists this value is returned
  double? asFloat(String key, {String? section, double? defaultValue}) {
    var rc = defaultValue;
    final value = asString(key,
        section: section,
        defaultValue: defaultValue == null ? null : defaultValue.toString());
    if (value != null) {
      rc = double.parse(value);
    }
    return rc;
  }

  /// Returns an int value given by [section] and [key].
  /// [key]: the key of the (key value) pair
  /// [section]: if given the (key value) pair is searched in this section
  /// [defaultValue]: if the key does not exists this value is returned
  int? asInt(String key, {String? section, int? defaultValue}) {
    var rc = defaultValue;
    final value = asString(key,
        section: section,
        defaultValue: defaultValue == null ? null : defaultValue.toString());
    if (value != null) {
      rc = int.parse(value);
    }
    return rc;
  }

  /// Returns a string value given by [section] and [key].
  /// [key]: the key of the (key value) pair
  /// [section]: if given the (key value) pair is searched in this section
  /// [defaultValue]: if the key does not exists this value is returned
  String? asString(String key, {String? section, String? defaultValue}) {
    var rc = defaultValue;
    Map? map = yamlMap;
    if (section != null) {
      map = null;
      if (yamlMap.containsKey(section)) {
        map = yamlMap[section];
      }
    }
    if (map != null && map.containsKey(key)) {
      rc = map[key].toString();
    }
    return rc;
  }
}
