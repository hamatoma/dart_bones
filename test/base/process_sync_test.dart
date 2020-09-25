import 'package:test/test.dart';
import 'package:dart_bones/dart_bones.dart';
void main() {
  var logger = MemoryLogger(LEVEL_FINE);
  ProcessSync.setLogger(logger);
  FileSync.setLogger(logger);
  group('Process', () {
    test('executeToString', () {
      var string = ProcessSync.executeToString('echo', ['Hi']);
      expect('Hi\n', equals(string));
    });
    test('executeToString-input', () {
      var string = ProcessSync.executeToString('echo', null, input: 'Hi');
      expect('\n', equals(string));
    });
    test('executeToString-error', () {
      var string = ProcessSync.executeToString('tail', ['not.exists'], prefixLogOutput: '===');
      expect('', equals(string));
    });
  });
  group('Script', () {
    test('executeAsScript', () {
      var logger2 = MemoryLogger(LEVEL_FINE);
      ProcessSync.executeAsScript('echo wow\npwd',
          prefixLogOutput: '', logger: logger2);
      expect(logger2.contains('wow'), isTrue);
      expect(logger2.contains('dart_bones'), isTrue);
    });
    test('executeAsScript-workingDir', () {
      var logger2 = MemoryLogger(LEVEL_FINE);
      ProcessSync.executeAsScript(
          'pwd', workingDirectory: '/etc/default',
          prefixLogOutput: '',
          logger: logger2);
      expect(logger2.contains('/etc/default'), isTrue);
    });
    test('executeAsScript-env', () {
      var logger2 = MemoryLogger(LEVEL_FINE);
      var env = {'MY_VAR': 'BLUB'};
      ProcessSync.executeAsScript(
          'echo xxx:\$MY_VAR\nenv', environment: env,
          prefixLogOutput: '',
          logger: logger2);
      expect(logger2.contains('xxx:BLUB'), isTrue);
    });
  });
}
