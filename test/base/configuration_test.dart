import 'package:path/path.dart' as package_path;
import 'package:dart_bones/src/base/base_logger.dart';
import 'package:dart_bones/src/base/file_sync_io.dart';
import 'package:dart_bones/src/base/memory_logger.dart';
import 'package:dart_bones/src/base/base_configuration.dart';
import 'package:dart_bones/src/base/configuration_io.dart';
import 'package:test/test.dart';

void main() {
  final logger = MemoryLogger(LEVEL_FINE);
  final _fileSync = FileSync.initialize(logger);
  var base = '';
  var fnConfig = '';
  var config = BaseConfiguration({}, logger);
  setUpAll(() {
    base = _fileSync.tempFile('unittest.config');
    fnConfig = _fileSync.tempFile('test.yaml', subDirs: 'unittest.config');
    buildConfig(fnConfig);
    config = Configuration(base, 'test', logger);
  });
  group('Basics', () {
    test('basic', () {
      expect(config, isNotNull);
      expect((config as Configuration).filename, equals(fnConfig));
      logger.log('expecting error: does not exist:');
      final config2 = Configuration(base, 'not_exists', logger);
      expect(config2.filename, isNull);
      final config3 = Configuration.constructed(logger, map: { 'a' : 33});
      expect(config3.asInt('a'), equals(33));
    });
  });
  group('getter', () {
    test('asString', () {
      expect(config.asString('name'), equals('Jonny Doo'));
      expect(config.asString('not-exists', defaultValue: 'unknown'),
          equals('unknown'));
      expect(config.asString('not-exists', section: 'dummy'),
          equals(null));
      expect(config.asString('name', section: 'db', defaultValue: 'unknown'),
          equals('doodle'));
      expect(
          config.asString('name', section: '3rdParty', defaultValue: 'unknown'),
          equals('unknown'));
    });
    test('asInt', () {
      expect(config.asInt('port'), equals(44));
      expect(config.asInt('port2', defaultValue: -1), equals(-1));
      expect(config.asInt('port', section: 'db'), equals(22033));
      expect(config.asInt('port', section: '3rdParty', defaultValue: -2),
          equals(-2));
    });
    test('asBool', () {
      expect(config.asBool('ignore'), isTrue);
      expect(config.asBool('relational'), isFalse);
      expect(config.asBool('ignore', section: 'db'), isFalse);
      expect(config.asBool('relational', section: 'db'), isTrue);
      expect(config.asBool('unknown'), isFalse);
      expect(config.asBool('unknown', section: 'db'), isFalse);
    });
    test('asFloat', () {
      expect(config.asFloat('width'), equals(33.5));
      expect(config.asFloat('height', defaultValue: 22.5), equals(22.5));
      expect(config.asFloat('size', section: 'widget'), equals(10.0));
      expect(config.asFloat('height2', section: 'widget', defaultValue: -2.0),
          equals(-2.0));
      expect(config.asFloat('height', section: 'widget'), equals(33.5));
    });
  });
  group('constructors', () {
    test('fromFile', () {
      final fnConfig2 = package_path.join(base, 'sample.yaml');
      _fileSync.toFile(fnConfig2, 'count: 123');
      final config2 = Configuration.fromFile(fnConfig2, logger);
      expect(config2.asInt('count'), equals(123));
    });
    test('standard', () {
      final fnConfig2 = package_path.join(base, 'sample.yaml');
      _fileSync.toFile(fnConfig2, 'count: 123');
      final config2 = Configuration(base, 'sample.yaml', logger);
      expect(config2.asInt('count'), equals(123));
    });
    test('fromFile', () {
      final fnConfig2 = package_path.join(base, 'sample_not_exist.yaml');
      final config2 = Configuration.fromFile(fnConfig2, logger);
      expect(config2.asInt('count'), equals(null));
    });
    test('constructed', () {
      final map = <String, dynamic>{ 'number': 99,
      'adam': <String, dynamic>{  'name': 'Doo', 'id': 432
        }
      };
      final config2 = BaseConfiguration(map, logger);
      expect(config2.asInt('number'), equals(99));
      expect(config2.asString('name', section: 'adam'), equals('Doo'));
      expect(config2.asInt('id', section: 'adam'), equals(432));
    });
  });
}

void buildConfig(String filename) {
  FileSync().toFile(filename, '''# Example configuration
name: "Jonny Doo"
port: 44
ignore: true
relational: false
width: 33.5
widget:
  size: 10
  height: 33.5
db:
  name: doodle
  port: 22033
  ignore: false
  relational: true
''');
}
