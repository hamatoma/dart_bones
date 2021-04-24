import 'dart:io';

import 'package:dart_bones/src/base/file_sync_io.dart';
import 'package:test/test.dart';

bool fileNotExists(path) =>
    FileMatcher(FileMatchingMode.fileNotExists).matches(path, {});

bool isDir(path) => FileMatcher(FileMatchingMode.isDir).matches(path, {});

bool isFile(path) => FileMatcher(FileMatchingMode.isFile).matches(path, {});
bool isLink(path) => FileMatcher(FileMatchingMode.isLink).matches(path, {});
bool testFile(mode, path) => FileMatcher(mode).matches(path, {});
class FileMatcher extends Matcher {
  final FileMatchingMode _mode;
  final _fileSync = FileSync();
  FileMatcher(FileMatchingMode mode) : _mode = mode;
  @override
  Description describe(Description description) => description
      .add('status of a file or directory')
      .addDescriptionOf(collapseWhitespace(_mode.toString()));

  @override
  bool matches(path, Map matchState) {
    bool rc;
    switch (_mode) {
      case FileMatchingMode.isDir:
        rc = _fileSync.isDir(path);
        break;
      case FileMatchingMode.isLink:
        rc = _fileSync.isLink(path);
        break;
      case FileMatchingMode.isFile:
        rc = _fileSync.isFile(path);
        break;
      case FileMatchingMode.fileNotExists:
        rc = !File(path).existsSync();
        break;
    }
    return rc;
  }
}
enum FileMatchingMode { fileNotExists, isDir, isFile, isLink }
