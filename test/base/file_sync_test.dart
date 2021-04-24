import 'dart:io';

import 'package:path/path.dart' as package_path;
import 'package:test/test.dart';
import 'package:dart_bones/src/base/memory_logger.dart';
import 'package:dart_bones/src/base/base_logger.dart';
import 'package:dart_bones/src/base/file_sync_io.dart';
import 'package:dart_bones/src/base/string_utils.dart';

import 'asserts.dart';

void main() {
  final logger = MemoryLogger(LEVEL_FINE);
  final fileSync = FileSync.initialize(logger);
  fileSync.clearDirectory('/tmp/unittest');
  group('TempDir', () {
    test('tempFile', () {
      final fn = fileSync.tempFile('abc.txt');
      expect(fn, equals('/tmp/abc.txt'));
    });
    test('tempFile-subdir', () {
      final fn = fileSync.tempFile('abc.txt', subDirs: 'unittest');
      expect(fn, equals('/tmp/unittest/abc.txt'));
      // expect(true, isDir('/tmp/unittest'));
    });
    test('tempFile-subdir2', () {
      final fn = fileSync.tempFile('abc.txt', subDirs: 'unittest/dir1/dir2');
      expect(fn, equals('/tmp/unittest/dir1/dir2/abc.txt'));
      // expect(true, isDir('/tmp/unittest/dir1/dir2'));
    });
    test('tempDirectory', () {
      final dir1 =
          fileSync.tempDirectory('abc.dir', subDirs: 'unittest/dir1/dir2');
      expect(dir1.endsWith('unittest/dir1/dir2/abc.dir'), isTrue);
      expect(fileSync.isDir(dir1), isTrue);
      final dir2 = fileSync.tempDirectory('unittest2');
      expect(fileSync.isDir(dir2), isTrue);
    });
  });
  group('rights', () {
    test('isDir', () {
      expect(fileSync.isDir('/etc'), isTrue);
    });
    test('isDir-file', () {
      expect(fileSync.isDir('/etc/passwd'), isFalse);
    });
    test('isDir-missing', () {
      expect(fileSync.isDir('/rtlpfmt'), isFalse);
    });
    test('isDir-link', () {
      expect(fileSync.isDir('/etc/alternatives/vi'), isFalse);
    });

    test('isFile', () {
      expect(fileSync.isFile('/etc/passwd'), isTrue);
    });
    test('isFile-missing', () {
      expect(fileSync.isFile('/rtlpfmt'), isFalse);
    });
    test('isFile-dir', () {
      expect(fileSync.isFile('/etc'), isFalse);
    });
    test('isFile-link', () {
      expect(fileSync.isFile('/etc/alternatives/vi'), isFalse);
    });
    test('isLink', () {
      expect(fileSync.isLink('/etc/alternatives/vi'), isTrue);
    });
    test('isLink-missing', () {
      expect(fileSync.isLink('/rtlpfmt'), isFalse);
    });
    test('isLink-dir', () {
      expect(fileSync.isLink('/etc'), isFalse);
    });
    test('isLink-link', () {
      expect(fileSync.isLink('/etc/passwd'), isFalse);
    });
  });
  group('string', () {
    test('toFile+fileAsString', () {
      final content = 'Hello world\nNice to see you';
      final fn = fileSync.tempFile('example.txt', subDirs: 'unittest');
      fileSync.toFile(fn, content);
      final current = fileSync.fileAsString(fn);
      expect(current, equals(content));
    });
    test('fileAsString-error', () {
      final fn = fileSync.tempFile('example1.not.exists', subDirs: 'unittest');
      final current = fileSync.fileAsString(fn);
      expect(current.length, equals(0));
      expect(logger.matches(r'cannot read.*example1.not.exists'), isTrue);
    });

    test('fileAsList', () {
      final content = 'Whoop\nHave a nice day!';
      final fn = fileSync.tempFile('example.txt', subDirs: 'unittest');
      fileSync.toFile(fn, content);
      final current = fileSync.fileAsList(fn);
      expect(current, equals(content.split('\n')));
    });
    test('fileAsList-error', () {
      final fn = fileSync.tempFile('example.not.exists', subDirs: 'unittest');
      final current = fileSync.fileAsList(fn);
      expect(current.length, equals(0));
      expect(logger.matches(r'cannot read.*example.not.exists'), isTrue);
    });
    test('toFile-date', () {
      final fn = fileSync.tempFile('example2.txt', subDirs: 'unittest');
      final date = stringToDateTime('2020.01.02-3:44');
      fileSync.toFile(fn, null, date: date);
      expect(File(fn)
          .statSync()
          .modified, equals(date));
    });
    test('toFile-dateasstring', () {
      final fn = fileSync.tempFile('example3.txt', subDirs: 'unittest');
      final date = stringToDateTime('2020.01.03-17:22');
      fileSync.toFile(fn, null, dateAsString: '2020.01.03-17:22');
      expect(File(fn).statSync().modified, equals(date));
    });
    test('toFile-asTransaction', () {
      final content = 'Hello world\nNice to see you';
      final fn = fileSync.tempFile('example4.txt', subDirs: 'unittest');
      fileSync.toFile(fn, content, asTransaction: true);
      final current = fileSync.fileAsString(fn);
      expect(current, equals(content));
    });
    test('toFile-inline', () {
      final content = 'Hello world\nNice to see you';
      final fn = fileSync.tempFile('example5.txt', subDirs: 'unittest');
      fileSync.toFile(fn, '');
      fileSync.toFile(fn, content, inline: true);
      final current = fileSync.fileAsString(fn);
      expect(current, equals(content));
    });
    test('toFile-mode', () {
      final content = 'Hello world\nNice to see you';
      final fn = fileSync.tempFile('example6.txt', subDirs: 'unittest');
      fileSync.toFile(fn, content, mode: 384 /* 0o600 */);
      final current = fileSync.fileAsString(fn);
      expect(current, equals(content));
      expect(File(fn).statSync().mode % 512, equals(384));
    });
    test('humanSize', () {
      expect(fileSync.humanSize(123), equals('123B'));
      expect(fileSync.humanSize(123456), equals('123.456KB'));
      expect(fileSync.humanSize(123456789), equals('123.457MB'));
      expect(fileSync.humanSize(123456789012), equals('123.457GB'));
      expect(fileSync.humanSize(123456789012456), equals('123.457TB'));
    });
    test('nativePath', () {
      expect(fileSync.nativePath('/a/path/abc.de', nativeSep: '|'),
          equals('|a|path|abc.de'));
      expect(fileSync.nativePath('a/path/abc.de', nativeSep: '|'),
          equals('a|path|abc.de'));
      expect(fileSync.nativePath('/a/path', appendix: '/d1/f1', nativeSep: '|'),
          equals('|a|path|d1|f1'));
      expect(
          fileSync.nativePath('/a/path/',
              appendixes: ['x', 'y'], nativeSep: '|'),
          equals('|a|path|x|y'));
      if (Platform.isLinux) {
        expect(fileSync.nativePath('/a/path/', appendixes: ['x', 'y']),
            equals('/a/path/x/y'));
      }
    });
    test('nodeOf', () {
      expect(package_path.basename('abc.de'), equals('abc.de'));
      expect(package_path.basename('path/a'), equals('a'));
      expect(package_path.basename('/base/in/path/abc.de'), equals('abc.de'));
    });
    test('parentOf', () {
      //expect(package_path.dirname('abc.de'), equals(''));
      //expect(package_path.dirname('path/a'), equals('path/'));
      //expect(FileSync().parentOf('path/a', trailingSlash: false), equals('path'));
      //expect(FileSync().parentOf('/', trailingSlash: false), equals(''));
      //expect(
      //    package_path.dirname('/base/in/path/abc.de'), equals('/base/in/path/'));
    });
    test('extensionOf', () {
      expect(package_path.extension('abc.blub.de'), equals('.de'));
      expect(package_path.extension('.de'), equals(''));
      expect(package_path.extension('path/a'), equals(''));
      expect(package_path.extension('/base/in.path/abc.de'), equals('.de'));
      expect(package_path.extension('/base/in.path/.de'), equals(''));
    });
    test('filenameOf', () {
      expect(fileSync.filenameOf('abc.blub.de'), equals('abc.blub'));
      expect(fileSync.filenameOf('.de'), equals('.de'));
      expect(fileSync.filenameOf('path/a'), equals('a'));
      expect(fileSync.filenameOf('/base/in.path/abc.de'), equals('abc'));
      expect(fileSync.filenameOf('/base/in.path/.de'), equals('.de'));
    });
    test('joinPath', () {
      //expect(package_path.join('/a', '/b'), equals('/a/b'));
      //expect(package_path.join('/a/', '/b'), equals('/a/b'));
      //expect(package_path.join('/a/', 'b'), equals('/a/b'));
      expect(package_path.join('/a', ''), equals('/a'));
      //expect(package_path.join('/a', '/b', '/c'), equals('/a/b/c'));
      //expect(package_path.join('/a', './b', './c'), equals('/a/b/c'));
      //expect(package_path.join('/a/', '/b/', '/c'), equals('/a/b/c'));
      //expect(package_path.join('/a/', '/b/', 'c'), equals('/a/b/c'));
      expect(package_path.join('/a/', '', 'c'), equals('/a/c'));
    });
  });
  group('node', () {
    test('chmod', () {
      final fn = fileSync.tempFile('chmod.test', subDirs: 'unittest');
      fileSync.toFile(fn, '');
      fileSync.chmod(fn, 509 /* = 0o775 */);
      expect(FileStat.statSync(fn).modeString(), equals('rwxrwxr-x'));
      fileSync.chmod(fn, 418 /* = 0o642 */);
      expect(FileStat.statSync(fn).modeString(), equals('rw-r---w-'));
    });
    test('entry', () {
      expect(fileSync.entry('/etc/passwd') is File, isTrue);
      expect(fileSync.entry('/etc') is Directory, isTrue);
      expect(fileSync.entry('/p') is Link, isTrue);
    });
    test('tail', () {
      final filename = fileSync.tempFile('tail.test', subDirs: 'unittest');
      fileSync.toFile(filename, r'''1
2
3
4''');
      expect(fileSync.tail(filename, 2).join('+'), equals('3+4'));
      expect(fileSync.tail(filename, 3, reversed: true).join('+'),
          equals('4+3+2'));
    });
  });
  group('directory', () {
    test('ensureDirectory', () {
      logger.clear();
      final dir = fileSync.tempFile('dir.01', subDirs: 'unittest');
      fileSync.ensureDirectory(dir);
      expect(true, isDir(dir));
      fileSync.ensureDoesNotExist(dir);
      expect(false, isDir(dir));
      fileSync.ensureDirectory(dir);
      final filename = package_path.join(dir, 'dummy.txt');
      fileSync.toFile(filename, '');
      fileSync.ensureDirectory(dir,
          clear: true, owner: 33, group: 33, mode: 0777);
      expect(false, isFile(filename));
      fileSync.ensureDirectory('/',
          clear: true, owner: 33, group: 33, mode: 0777);
      expect(logger.errors.length, equals(0));
    });
    test('ensureDirectory-trailing-slash', () {
      logger.clear();
      final dir =
          fileSync.tempFile('dir.slash', subDirs: 'unittest') + FileSync.sep;
      fileSync.ensureDirectory(dir);
      expect(true, isDir(dir));
    });
    test('ensureDoesNotExist', () {
      final fn = fileSync.tempFile('aFile.txt', subDirs: 'unittest');
      fileSync.toFile(fn, '');
      fileSync.ensureDoesNotExist(fn);
      expect(false, isFile(fn));
    });
    test('ensureDoesNotExist-link', () {
      final fn = fileSync.tempFile('aLink.txt', subDirs: 'unittest');
      if (!fileSync.isLink(fn)) {
        Link(fn).createSync('/rtrpfm');
      }
      expect(fileSync.isLink(fn), isTrue);
      fileSync.ensureDoesNotExist(fn);
      expect(false, isFile(fn));
    });
    test('ensureDoesNotExist-error', () {
      final dir1 = fileSync.tempDirectory(
          'unittest.trigger.ensureDoesNotExist.error',
          subDirs: 'unittest');
      try {
        fileSync.ensureDoesNotExist(dir1);
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
      final dir1 = fileSync.tempFile(
          'unittest.trigger.ensureDoesNotExist.error',
          subDirs: 'unittest');
      fileSync.toFile(dir1, '');
      try {
        fileSync.ensureDoesNotExist(dir1);
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
      fileSync.chdir('/etc');
      expect(Directory.current.path, equals('/etc'));
      fileSync.chdir(current);
    });
    test('chdir-error', () {
      final current = Directory.current.path;
      expect(fileSync.chdir('/not.realy.exists'), isFalse);
      expect(fileSync.chdir('/not.realy.exists', ignoreErrors: true), isFalse);
      expect(fileSync.chdir('/etc/crontab'), isFalse);
      expect(Directory.current.path, equals(current));
      fileSync.chdir(current);
      final dir1 = fileSync.tempFile('unittest.trigger.chdir.error',
          subDirs: 'unittest');
      fileSync.chdir(dir1);
      expect(logger.matches(r'.*cannot chdir to.*unittest.trigger.chdir.error'),
          isTrue);
    });
    test('chown', () {
      fileSync.chown('/tmp/not.exists', 33, group: 33);
    });
    test('clearDirectory', () {
      final dir = fileSync.tempFile('clean.dir', subDirs: 'unittest');
      fileSync.ensureDirectory(dir);
      final file1 = fileSync.tempFile('f1.dat', subDirs: 'unittest/clean.dir');
      fileSync.toFile(file1, '1');
      final dir2 = fileSync.tempFile('dir2', subDirs: 'unittest/clean.dir');
      fileSync.ensureDirectory(dir2);
      final file2 =
      fileSync.tempFile('f2.dat', subDirs: 'unittest/clean.dir/dir2');
      fileSync.toFile(file2, '2');
      expect(fileSync.clearDirectory(file1), isFalse);
      expect(fileSync.clearDirectory(dir, testSuccess: true), isTrue);
      expect(File(file1).existsSync(), isFalse);
      expect(File(file2).existsSync(), isFalse);
      expect(File(dir2).existsSync(), isFalse);
    });
    test('createTree', () {
      final base = fileSync.tempFile('new.dir', subDirs: 'unittest');
      fileSync.ensureDirectory(base, clear: true);
      final files = ['dir1/dir1_1/file2', 'dir1/dir1_2/', 'file1.dat'];
      fileSync.createTree(base, files);
      expect(
          fileSync.fileAsString(fileSync.nativePath(base, appendix: files[0])),
          equals(files[0]));
      expect(
          fileSync.fileAsString(fileSync.nativePath(base, appendix: files[2])),
          equals(files[2]));
      expect(
          Directory(fileSync.nativePath(base, appendix: files[1])).existsSync(),
          isTrue);
      fileSync.createTree(base, ['onTemp']);
      final filename = package_path.join(base, 'onTemp');
      expect(File(filename).existsSync(), isTrue);
      fileSync.createTree(null, ['onTemp']);
    });

    test('pushd', () {
      final expected = Directory.current.path;
      final current = fileSync.pushd('/etc');
      expect(Directory.current.path, equals('/etc'));
      expect(current, equals(expected));
      fileSync.chdir(expected);
    });
  });
  fileSync.ensureDoesNotExist('/tmp/unittest', recursive: true);
}
