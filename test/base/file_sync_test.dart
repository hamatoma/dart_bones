import 'dart:io';

import 'package:dart_bones/dart_bones.dart';
import 'package:test/test.dart';

import 'asserts.dart';

void main() {
  final logger = MemoryLogger(LEVEL_FINE);
  FileSync.setLogger(logger);
  FileSync.clearDirectory('/tmp/unittest');
  group('TempDir', () {
    test('tempFile', () {
      final fn = FileSync.tempFile('abc.txt');
      expect(fn, equals('/tmp/abc.txt'));
    });
    test('tempFile-subdir', () {
      final fn = FileSync.tempFile('abc.txt', subDirs: 'unittest');
      expect(fn, equals('/tmp/unittest/abc.txt'));
      // expect(true, isDir('/tmp/unittest'));
    });
    test('tempFile-subdir2', () {
      final fn = FileSync.tempFile('abc.txt', subDirs: 'unittest/dir1/dir2');
      expect(fn, equals('/tmp/unittest/dir1/dir2/abc.txt'));
      // expect(true, isDir('/tmp/unittest/dir1/dir2'));
    });
    test('tempDirectory', () {
      final dir1 =
          FileSync.tempDirectory('abc.dir', subDirs: 'unittest/dir1/dir2');
      expect(dir1.endsWith('unittest/dir1/dir2/abc.dir'), isTrue);
      expect(FileSync.isDir(dir1), isTrue);
      final dir2 = FileSync.tempDirectory('unittest2');
      expect(FileSync.isDir(dir2), isTrue);
    });
  });
  group('rights', () {
    test('isDir', () {
      expect(FileSync.isDir('/etc'), isTrue);
    });
    test('isDir-file', () {
      expect(FileSync.isDir('/etc/passwd'), isFalse);
    });
    test('isDir-missing', () {
      expect(FileSync.isDir('/rtlpfmt'), isFalse);
    });
    test('isDir-link', () {
      expect(FileSync.isDir('/etc/alternatives/vi'), isFalse);
    });

    test('isFile', () {
      expect(FileSync.isFile('/etc/passwd'), isTrue);
    });
    test('isFile-missing', () {
      expect(FileSync.isFile('/rtlpfmt'), isFalse);
    });
    test('isFile-dir', () {
      expect(FileSync.isFile('/etc'), isFalse);
    });
    test('isFile-link', () {
      expect(FileSync.isFile('/etc/alternatives/vi'), isFalse);
    });
    test('isLink', () {
      expect(FileSync.isLink('/etc/alternatives/vi'), isTrue);
    });
    test('isLink-missing', () {
      expect(FileSync.isLink('/rtlpfmt'), isFalse);
    });
    test('isLink-dir', () {
      expect(FileSync.isLink('/etc'), isFalse);
    });
    test('isLink-link', () {
      expect(FileSync.isLink('/etc/passwd'), isFalse);
    });
  });
  group('string', () {
    test('toFile+fileAsString', () {
      final content = 'Hello world\nNice to see you';
      final fn = FileSync.tempFile('example.txt', subDirs: 'unittest');
      FileSync.toFile(fn, content);
      final current = FileSync.fileAsString(fn);
      expect(current, equals(content));
    });
    test('fileAsString-error', () {
      final fn = FileSync.tempFile('example1.not.exists', subDirs: 'unittest');
      final current = FileSync.fileAsString(fn);
      expect(current.length, equals(0));
      expect(logger.matches(r'cannot read.*example1.not.exists'), isTrue);
    });

    test('fileAsList', () {
      final content = 'Whoop\nHave a nice day!';
      final fn = FileSync.tempFile('example.txt', subDirs: 'unittest');
      FileSync.toFile(fn, content);
      final current = FileSync.fileAsList(fn);
      expect(current, equals(content.split('\n')));
    });
    test('fileAsList-error', () {
      final fn = FileSync.tempFile('example.not.exists', subDirs: 'unittest');
      final current = FileSync.fileAsList(fn);
      expect(current.length, equals(0));
      expect(logger.matches(r'cannot read.*example.not.exists'), isTrue);
    });
    test('toFile-date', () {
      final fn = FileSync.tempFile('example2.txt', subDirs: 'unittest');
      final date = StringUtils.stringToDateTime('2020.01.02-3:44');
      FileSync.toFile(fn, null, date: date);
      expect(File(fn)
          .statSync()
          .modified, equals(date));
    });
    test('toFile-dateasstring', () {
      final fn = FileSync.tempFile('example3.txt', subDirs: 'unittest');
      final date = StringUtils.stringToDateTime('2020.01.03-17:22');
      FileSync.toFile(fn, null, dateAsString: '2020.01.03-17:22');
      expect(File(fn).statSync().modified, equals(date));
    });
    test('toFile-asTransaction', () {
      final content = 'Hello world\nNice to see you';
      final fn = FileSync.tempFile('example4.txt', subDirs: 'unittest');
      FileSync.toFile(fn, content, asTransaction: true);
      final current = FileSync.fileAsString(fn);
      expect(current, equals(content));
    });
    test('toFile-inline', () {
      final content = 'Hello world\nNice to see you';
      final fn = FileSync.tempFile('example5.txt', subDirs: 'unittest');
      FileSync.toFile(fn, '');
      FileSync.toFile(fn, content, inline: true);
      final current = FileSync.fileAsString(fn);
      expect(current, equals(content));
    });
    test('toFile-mode', () {
      final content = 'Hello world\nNice to see you';
      final fn = FileSync.tempFile('example6.txt', subDirs: 'unittest');
      FileSync.toFile(fn, content, mode: 384 /* 0o600 */);
      final current = FileSync.fileAsString(fn);
      expect(current, equals(content));
      expect(File(fn).statSync().mode % 512, equals(384));
    });
    test('humanSize', () {
      expect(FileSync.humanSize(123), equals('123B'));
      expect(FileSync.humanSize(123456), equals('123.456KB'));
      expect(FileSync.humanSize(123456789), equals('123.457MB'));
      expect(FileSync.humanSize(123456789012), equals('123.457GB'));
      expect(FileSync.humanSize(123456789012456), equals('123.457TB'));
    });
    test('nativePath', () {
      expect(FileSync.nativePath('/a/path/abc.de', nativeSep: '|'),
          equals('|a|path|abc.de'));
      expect(FileSync.nativePath('a/path/abc.de', nativeSep: '|'),
          equals('a|path|abc.de'));
      expect(FileSync.nativePath('/a/path', appendix: '/d1/f1', nativeSep: '|'),
          equals('|a|path|d1|f1'));
      expect(
          FileSync.nativePath('/a/path/',
              appendixes: ['x', 'y'], nativeSep: '|'),
          equals('|a|path|x|y'));
      if (Platform.isLinux) {
        expect(FileSync.nativePath('/a/path/', appendixes: ['x', 'y']),
            equals('/a/path/x/y'));
      }
    });
    test('nodeOf', () {
      expect(FileSync.nodeOf('abc.de'), equals('abc.de'));
      expect(FileSync.nodeOf('path/a'), equals('a'));
      expect(FileSync.nodeOf('/base/in/path/abc.de'), equals('abc.de'));
    });
    test('parentOf', () {
      expect(FileSync.parentOf('abc.de'), equals(''));
      expect(FileSync.parentOf('path/a'), equals('path/'));
      expect(
          FileSync.parentOf('/base/in/path/abc.de'), equals('/base/in/path/'));
    });
    test('extensionOf', () {
      expect(FileSync.extensionOf('abc.blub.de'), equals('.de'));
      expect(FileSync.extensionOf('.de'), equals(''));
      expect(FileSync.extensionOf('path/a'), equals(''));
      expect(FileSync.extensionOf('/base/in.path/abc.de'), equals('.de'));
      expect(FileSync.extensionOf('/base/in.path/.de'), equals(''));
    });
    test('filenameOf', () {
      expect(FileSync.filenameOf('abc.blub.de'), equals('abc.blub'));
      expect(FileSync.filenameOf('.de'), equals('.de'));
      expect(FileSync.filenameOf('path/a'), equals('a'));
      expect(FileSync.filenameOf('/base/in.path/abc.de'), equals('abc'));
      expect(FileSync.filenameOf('/base/in.path/.de'), equals('.de'));
    });
    test('joinPath', () {
      expect(FileSync.joinPaths('/a', '/b'), equals('/a/b'));
      expect(FileSync.joinPaths('/a/', '/b'), equals('/a/b'));
      expect(FileSync.joinPaths('/a/', 'b'), equals('/a/b'));
      expect(FileSync.joinPaths('/a', ''), equals('/a'));
      expect(FileSync.joinPaths('/a', '/b', '/c'), equals('/a/b/c'));
      expect(FileSync.joinPaths('/a', './b', './c'), equals('/a/b/c'));
      expect(FileSync.joinPaths('/a/', '/b/', '/c'), equals('/a/b/c'));
      expect(FileSync.joinPaths('/a/', '/b/', 'c'), equals('/a/b/c'));
      expect(FileSync.joinPaths('/a/', '', 'c'), equals('/a/c'));
    });
  });
  group('node', () {
    test('chmod', () {
      final fn = FileSync.tempFile('chmod.test', subDirs: 'unittest');
      FileSync.toFile(fn, '');
      FileSync.chmod(fn, 509 /* = 0o775 */);
      expect(FileStat.statSync(fn).modeString(), equals('rwxrwxr-x'));
      FileSync.chmod(fn, 418 /* = 0o642 */);
      expect(FileStat.statSync(fn).modeString(), equals('rw-r---w-'));
    });
    test('entry', () {
      expect(FileSync.entry('/etc/passwd') is File, isTrue);
      expect(FileSync.entry('/etc') is Directory, isTrue);
      expect(FileSync.entry('/p') is Link, isTrue);
    });
    test('tail', () {
      final filename = FileSync.tempFile('tail.test', subDirs: 'unittest');
      FileSync.toFile(filename, r'''1
2
3
4''');
      expect(FileSync.tail(filename, 2).join('+'), equals('3+4'));
      expect(FileSync.tail(filename, 3, reversed: true).join('+'),
          equals('4+3+2'));
    });
  });
  group('directory', () {
    test('ensureDirectory', () {
      final dir = FileSync.tempFile('dir.01', subDirs: 'unittest');
      FileSync.ensureDirectory(dir);
      expect(true, isDir(dir));
      FileSync.ensureDoesNotExist(dir);
      expect(false, isDir(dir));
      FileSync.ensureDirectory(dir);
      final filename = FileSync.joinPaths(dir, 'dummy.txt');
      FileSync.toFile(filename, '');
      FileSync.ensureDirectory(dir,
          clear: true, owner: 33, group: 33, mode: 0777);
      expect(false, isFile(filename));
    });
    test('ensureDirectory', () {
      final dir = FileSync.tempFile('dir.01', subDirs: 'unittest');
      FileSync.ensureDirectory(dir);
      expect(true, isDir(dir));
      FileSync.ensureDoesNotExist(dir);
      expect(false, isDir(dir));
    });
    test('ensureDoesNotExist', () {
      final fn = FileSync.tempFile('aFile.txt', subDirs: 'unittest');
      FileSync.toFile(fn, '');
      FileSync.ensureDoesNotExist(fn);
      expect(false, isFile(fn));
    });
    test('ensureDoesNotExist-link', () {
      final fn = FileSync.tempFile('aLink.txt', subDirs: 'unittest');
      if (!FileSync.isLink(fn)) {
        Link(fn).createSync('/rtrpfm');
      }
      expect(FileSync.isLink(fn), isTrue);
      FileSync.ensureDoesNotExist(fn);
      expect(false, isFile(fn));
    });
    test('ensureDoesNotExist-error', () {
      final dir1 = FileSync.tempDirectory(
          'unittest.trigger.ensureDoesNotExist.error',
          subDirs: 'unittest');
      try {
        FileSync.ensureDoesNotExist(dir1);
        expect(false, isTrue);
      } on Exception catch (exc) {
        final text = '$exc';
        expect(
            text.endsWith(
                'unittest.trigger.ensureDoesNotExist.error already exists'),
            isTrue);
      }
    });
    test('ensureDoesNotExist-file-error', () {
      final dir1 = FileSync.tempFile(
          'unittest.trigger.ensureDoesNotExist.error',
          subDirs: 'unittest');
      FileSync.toFile(dir1, '');
      try {
        FileSync.ensureDoesNotExist(dir1);
        expect(false, isTrue);
      } on Exception catch (exc) {
        final text = '$exc';
        expect(
            text.endsWith(
                'unittest.trigger.ensureDoesNotExist.error already exists'),
            isTrue);
      }
    });

    test('chdir', () {
      final current = Directory.current.path;
      FileSync.chdir('/etc');
      expect(Directory.current.path, equals('/etc'));
      FileSync.chdir(current);
    });
    test('chdir-error', () {
      final current = Directory.current.path;
      expect(FileSync.chdir('/not.realy.exists'), isFalse);
      expect(FileSync.chdir('/not.realy.exists', ignoreErrors: true), isFalse);
      expect(FileSync.chdir('/etc/crontab'), isFalse);
      expect(Directory.current.path, equals(current));
      FileSync.chdir(current);
      final dir1 = FileSync.tempFile('unittest.trigger.chdir.error',
          subDirs: 'unittest');
      FileSync.chdir(dir1);
      expect(logger.matches(r'.*cannot chdir to.*unittest.trigger.chdir.error'),
          isTrue);
    });
    test('chown', () {
      FileSync.chown('/tmp/not.exists', 33, group: 33);
    });
    test('clearDirectory', () {
      final dir = FileSync.tempFile('clean.dir', subDirs: 'unittest');
      FileSync.ensureDirectory(dir);
      final file1 = FileSync.tempFile('f1.dat', subDirs: 'unittest/clean.dir');
      FileSync.toFile(file1, '1');
      final dir2 = FileSync.tempFile('dir2', subDirs: 'unittest/clean.dir');
      FileSync.ensureDirectory(dir2);
      final file2 =
      FileSync.tempFile('f2.dat', subDirs: 'unittest/clean.dir/dir2');
      FileSync.toFile(file2, '2');
      expect(FileSync.clearDirectory(file1), isFalse);
      expect(FileSync.clearDirectory(dir, testSuccess: true), isTrue);
      expect(File(file1).existsSync(), isFalse);
      expect(File(file2).existsSync(), isFalse);
      expect(File(dir2).existsSync(), isFalse);
    });
    test('createTree', () {
      final base = FileSync.tempFile('new.dir', subDirs: 'unittest');
      FileSync.ensureDirectory(base, clear: true);
      final files = ['dir1/dir1_1/file2', 'dir1/dir1_2/', 'file1.dat'];
      FileSync.createTree(base, files);
      expect(
          FileSync.fileAsString(FileSync.nativePath(base, appendix: files[0])),
          equals(files[0]));
      expect(
          FileSync.fileAsString(FileSync.nativePath(base, appendix: files[2])),
          equals(files[2]));
      expect(
          Directory(FileSync.nativePath(base, appendix: files[1])).existsSync(),
          isTrue);
      FileSync.createTree(base, ['onTemp']);
      final filename = FileSync.joinPaths(base, 'onTemp');
      expect(File(filename).existsSync(), isTrue);
      FileSync.createTree(null, ['onTemp']);
    });

    test('pushd', () {
      final expected = Directory.current.path;
      final current = FileSync.pushd('/etc');
      expect(Directory.current.path, equals('/etc'));
      expect(current, equals(expected));
      FileSync.chdir(expected);
    });
  });
  FileSync.ensureDoesNotExist('/tmp/unittest', recursive: true);
}
