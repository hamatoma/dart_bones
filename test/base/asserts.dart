import 'package:test/test.dart';
import 'dart:io';
import 'package:dart_bones/dart_bones.dart';

enum FileMatchingMode {
  fileNotExists, isDir, isFile, isLink
}
class FileMatcher extends Matcher {
  final FileMatchingMode _mode;
  FileMatcher(FileMatchingMode mode) : _mode = mode;
  @override
  bool matches(path, Map matchState) {
    bool rc;
    switch(_mode){
      case FileMatchingMode.isDir:
        rc = FileSync.isDir(path);
        break;
      case FileMatchingMode.isLink:
        rc = FileSync.isLink(path);
        break;
      case FileMatchingMode.isFile:
        rc = FileSync.isFile(path);
        break;
      case FileMatchingMode.fileNotExists:
        rc = ! File(path).existsSync();
        break;
    }
    return rc;
  }
  @override
  Description describe(Description description) =>
      description.add('status of a file or directory').
      addDescriptionOf(collapseWhitespace(_mode.toString()));
}
bool testFile(mode, path) => FileMatcher(mode).matches(path, null);
bool isDir(path) => FileMatcher(FileMatchingMode.isDir).matches(path, null);
bool isFile(path) => FileMatcher(FileMatchingMode.isFile).matches(path, null);
bool isLink(path) => FileMatcher(FileMatchingMode.isLink).matches(path, null);
bool fileNotExists(path) => FileMatcher(FileMatchingMode.fileNotExists).matches(path, null);
