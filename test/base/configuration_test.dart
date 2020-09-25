import 'package:dart_bones/dart_bones.dart';
import 'package:dart_bones/src/base/configuration_io.dart' as config_io;
import 'package:test/test.dart';

void main() {
  final logger = MemoryLogger(LEVEL_FINE);
  String base;
  String fnConfig;
  Configuration config;
  setUpAll(() {
    base = FileSync.tempFile('unittest.config');
    fnConfig = FileSync.tempFile('test.yaml', subDirs: 'unittest.config');
    buildConfig(fnConfig);
    config = Configuration(base, 'test', logger);
  });
  group('Basics', () {
    test('basic', () {
      expect(config, isNotNull);
      expect(config.filename, equals(fnConfig));
      logger.log('expecting error: does not exist:');
      final config2 = Configuration(base, 'not_exists', logger);
      expect(config2.filename, isNull);
      final config3 = config_io.Configuration.constructed(logger, map: { 'a' : 33});
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
    });
  });
  group('constructors', () {
    test('fromFile', () {
      final fnConfig2 = FileSync.joinPaths(base, 'sample.yaml');
      FileSync.toFile(fnConfig2, 'count: 123');
      final config2 = Configuration.fromFile(fnConfig2, logger);
      expect(config2.asInt('count'), equals(123));
    });
    test('standard', () {
      final fnConfig2 = FileSync.joinPaths(base, 'sample.yaml');
      FileSync.toFile(fnConfig2, 'count: 123');
      final config2 = Configuration(base, 'sample.yaml', logger);
      expect(config2.asInt('count'), equals(123));
    });
    test('fromFile', () {
      final fnConfig2 = FileSync.joinPaths(base, 'sample_not_exist.yaml');
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
  FileSync.toFile(filename, '''# Example configuration
name: "Jonny Doo"
port: 44
ignore: true
relational: false
db:
  name: doodle
  port: 22033
  ignore: false
  relational: true
''');
}