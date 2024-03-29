import 'dart:io';

import 'package:path/path.dart' as package_path;
import 'package:sprintf/sprintf.dart';

import '../../dart_bones.dart';
import 'string_utils.dart' as string_utils;

/// Implements static functions for files and directories in the sync variant.
class FileSync {
  static final sep = Platform.pathSeparator;
  static final currentDirSep = '.' + Platform.pathSeparator;

  /// the singleton instance
  static FileSync? _instance;
  static final tempDir = Platform.isLinux ? '/tmp' : 'c:\\temp';
  BaseLogger _logger;

  /// The public constructor.
  /// If [logger] is null an isolated instance is returned. Otherwise a singleton.
  /// Note: normally the singleton instance should be used.
  /// Only in special cases like different threads ("isolates") isolated
  /// instances will be meaningful.
  factory FileSync([BaseLogger? logger]) {
    final rc = logger != null
        ? FileSync._internal(logger)
        : _instance ??= FileSync._internal(globalLogger);
    return rc;
  }

  /// Internal constructor
  FileSync._internal(this._logger);

  /// Changes the current directory to [path].
  /// Returns true on success.
  bool chdir(String path, {bool ignoreErrors = false}) {
    var rc = true;
    try {
      Directory.current = Directory(path);
    } catch (exc) {
      rc = false;
      if (!ignoreErrors) {
        if (!isDir(path) && !path.endsWith('unittest.trigger.chdir.error')) {
          _logger.error('cannot change to not existing directory $path');
        } else {
          _logger.error('cannot chdir to $path: $exc');
        }
      }
    }
    return rc;
  }

  /// Changes the permission rights of [filename] to [mode].
  void chmod(String filename, int mode) {
    final args = [
      sprintf('0%o', [mode]),
      filename
    ];
    _logger.log('chmod ' + args.join(' '), LEVEL_DETAIL);
    Process.runSync('/bin/chmod', args);
  }

  /// Changes the owner (und group) of the file [filename].
  void chown(String filename, int owner, {int? group}) {
    var user = owner.toString();
    if (group != null) {
      user += ':$group';
    }
    final args = [user, filename];
    _logger.log('chown ' + args.join(' '), LEVEL_DETAIL);
    Process.runSync('/bin/chown', args);
  }

  /// Deletes all entries of a [path].
  /// [testSuccess] true: it will be tested whether the directory is really empty
  /// result: true: [path] is a directory. if [testSuccess]: the directory is empty
  bool clearDirectory(String path, {testSuccess = false}) {
    final directory = Directory(path);
    var rc = directory.existsSync();
    if (rc) {
      for (var entity in directory.listSync()) {
        entity.deleteSync(recursive: true);
      }
    }
    if (rc && testSuccess) {
      rc = directory.listSync().isEmpty;
    }
    return rc;
  }

  /// Creates a directory tree with some files inside.
  /// This is useful for unittests.
  /// [base] the base directory. If null the temp directory is used
  /// [files] a list of files: if the entry ends with '/' this is an directory,
  /// e.g. ['dir1/file1', dir2/file2', 'dir1_1/']
  /// content of the created files is the filename with relative path (entry of [files])
  void createTree(String? base, List<String> files) {
    base ??= tempDir;
    ensureDirectory(base);
    if (!base.endsWith(sep)) {
      base += sep;
    }
    for (var file in files) {
      final full = base + file;
      if (file.endsWith('/')) {
        ensureDirectory(full);
      } else {
        final parent = package_path.dirname(full);
        ensureDirectory(parent);
        toFile(full, file);
      }
    }
  }

  /// Makes an directory if it does not exist.
  /// [path] the name of the directory
  /// [mode] the rights, e.g. 0o777 for all rights
  /// [owner] the UID of the owner
  /// [group] the GID of the owner group
  /// [clear] true: the directory will be cleared (all entries inside will be deleted)
  bool ensureDirectory(String path,
      {int? mode, int? owner, int? group, bool clear = false}) {
    var rc = true;
    // we do not handle '/':
    if (path != '/') {
      if (path.endsWith(sep)) {
        path = path.substring(0, path.length - 1);
      }
      final dir = Directory(path);
      if (!dir.existsSync()) {
        _logger.log('creating $path');
        try {
          dir.createSync(recursive: true);
        } on FileSystemException catch (exc) {
          _logger.error('cannot create $path: $exc');
          rc = false;
        }
      } else if (clear) {
        clearDirectory(path);
      }

      if (owner != null || group != null) {
        chown(path, owner ?? 0, group: group);
      }
      if (mode != null) {
        chmod(path, mode);
      }
    }
    return rc;
  }

  /// Removes a file/directory if it exists.
  /// [filename]: the full filename of the file/directory to remove
  /// [recursive]: true: remove the content of a directory too
  void ensureDoesNotExist(String filename, {bool recursive = false}) {
    if (FileSystemEntity.isDirectorySync(filename)) {
      _logger.log('removing the directory $filename');
      final entry = Directory(filename);
      entry.deleteSync(recursive: recursive);
      if (entry.existsSync() ||
          filename.endsWith('unittest.trigger.ensureDoesNotExist.error')) {
        throw Exception('directory $filename already exists');
      }
    } else if (isLink(filename)) {
      Link(filename).deleteSync();
    } else if (isFile(filename)) {
      _logger.log('removing the file $filename');
      File(filename).deleteSync();
      if (isFile(filename) ||
          filename.endsWith('unittest.trigger.ensureDoesNotExist.error')) {
        throw Exception('file $filename already exists');
      }
    }
  }

  /// Returns a Directory / File / Link instance of a given [filename].
  /// Returns null if no file exists with this name.
  FileSystemEntity? entry(String filename) {
    FileSystemEntity? rc;
    if (isDir(filename)) {
      rc = Directory(filename);
    } else if (isLink(filename)) {
      rc = Link(filename);
    } else if (isFile(filename)) {
      rc = File(filename);
    }
    return rc;
  }

  /// Returns the extension of the [path].
  /// The extension is the part behind the last '.'.
  /// If the only '.' is at the top, the result is '' otherwise the the last part with '.'.
  /// deprecated: Use extension() from package path
  @deprecated
  String extensionOf(String path) {
    var rc = '';
    final ix = path.lastIndexOf('.');
    final ixSlash = path.lastIndexOf(sep);
    if (ix > 0 && (ixSlash < 0 || ix > ixSlash + 1)) {
      rc = path.substring(ix);
    }
    return rc;
  }

  /// Reads the content of a file and return it as a list of lines.
  List<String> fileAsList(String filename) {
    final file = File(filename);
    var content = <String>[];
    try {
      content = file.readAsLinesSync();
    } on Exception catch (exc, stack) {
      _logger.error('cannot read $filename: ${exc.toString()}',
          stackTrace: stack);
    }
    return content;
  }

  /// Reads the content of a file and return it as a string.
  String fileAsString(String filename) {
    final file = File(filename);
    var content = '';
    try {
      content = file.readAsStringSync();
    } on Exception catch (exc, stack) {
      _logger.error('cannot read $filename: ${exc.toString()}',
          stackTrace: stack);
    }
    return content;
  }

  /// Returns the node of the [path] without the extension.
  /// The extension is the part behind the last '.'.
  /// If the only '.' is at the top, the result is '' otherwise the the last part with '.'.
  String filenameOf(String path) {
    var rc = '';
    final ix = path.lastIndexOf('.');
    final ixSlash = path.lastIndexOf(sep);
    if (ixSlash < 0) {
      if (ix <= 0) {
        rc = path;
      } else {
        rc = path.substring(0, ix);
      }
    } else {
      if (ix <= ixSlash + 1) {
        rc = path.substring(ixSlash + 1);
      } else if (ix > ixSlash + 1) {
        rc = path.substring(ixSlash + 1, ix);
      }
    }
    return rc;
  }

  /// Returns a human readable string of a file [size], e.g. '2.389MB'.
  String humanSize(int size) {
    String rc;
    String unit;
    if (size < 1000) {
      rc = size.toString() + 'B';
    } else {
      double size2;
      if (size < 1000000) {
        unit = 'KB';
        size2 = size / 1000.0;
      } else if (size < 1000000000) {
        unit = 'MB';
        size2 = size / 1000000.0;
      } else if (size < 1000000000000) {
        unit = 'GB';
        size2 = size / 1000000000.0;
      } else {
        unit = 'TB';
        size2 = size / 1000000000000.0;
      }
      rc = sprintf('%.3f%s', [size2, unit]);
    }
    return rc;
  }

  /// Returns true if [path] is a directory.
  /// [path]: the full name of the directory
  bool isDir(path) {
    var rc = FileSystemEntity.isDirectorySync(path);
    return rc;
  }

  /// Returns true if [path] is a "normal" file.
  /// [path]: the full name of the directory
  bool isFile(path) {
    var rc =
        FileSystemEntity.isFileSync(path) && !FileSystemEntity.isLinkSync(path);
    return rc;
  }

  /// Returns true if [path] is a symbolic link.
  /// [path]: the full name of the directory
  bool isLink(path) {
    var rc = Link(path).existsSync();
    return rc;
  }

  /// Joins parts to a combined path.
  /// [first]: first part
  /// [second]: second part
  /// [third]: third part
  /// deprecated: Use join() from package path
  @deprecated
  String joinPath(String first, String second, [String? third]) {
    final rc = StringBuffer(first);
    var last = first;
    if (second.isNotEmpty) {
      if (!first.endsWith(sep)) {
        rc.write(sep);
      }
      if (second.startsWith(currentDirSep)) {
        rc.write(second.substring(2));
      } else if (second.startsWith(sep)) {
        rc.write(second.substring(1));
      } else {
        rc.write(second);
      }
      last = second;
    }
    if (third != null && third.isNotEmpty) {
      if (!last.endsWith(sep)) {
        rc.write(sep);
      }
      if (third.startsWith(currentDirSep)) {
        rc.write(third.substring(2));
      } else if (third.startsWith(sep)) {
        rc.write(third.substring(1));
      } else {
        rc.write(third);
      }
    }
    return rc.toString();
  }

  /// Joins path components and converts the '/' to the native path separator.
  /// [path] the base path
  /// [appendix] will be appended to the path
  /// [appendixes] a list of nodes to append to the path
  /// [nativeSep] the native separator. If null the global native path separator is used
  String nativePath(String path,
      {String? appendix, List<String>? appendixes, String? nativeSep}) {
    var rc = path;
    nativeSep ??= sep;
    if (appendix != null) {
      rc += sep + appendix;
    }
    if (appendixes != null) {
      for (var item in appendixes) {
        rc += sep + item;
      }
    }
    rc = rc.replaceAll('/', nativeSep);
    rc = rc.replaceAll(nativeSep + nativeSep, nativeSep);
    return rc;
  }

  /// Returns the filename of the [path] without path.
  /// Example: base('abc/def.txt') == 'def.txt'
  /// deprecated: Use basename() from package path
  @deprecated
  String nodeOf(String path) {
    final ix = path.lastIndexOf(sep);
    final rc = ix < 0 ? path : path.substring(ix + 1);
    return rc;
  }

  /// Returns the parent directory of the [path].
  /// Example: dirname('abc/def.txt') == 'abc/'
  /// [trailingSlash]: if false the trailing slash will not be part of the result
  /// deprecated: Use dirname() from package path
  @deprecated
  String parentOf(String path, {bool trailingSlash = true}) {
    final ix = path.lastIndexOf(sep);
    final rc = ix < 0 ? '' : path.substring(0, ix + (trailingSlash ? 1 : 0));
    return rc;
  }

  /// Changes the current directory to [path].
  /// Returns null on error or the previous current directory.
  String? pushd(path) {
    String? rc = Directory.current.path;
    if (!chdir(path)) {
      rc = null;
    }
    return rc;
  }

  /// Sets the internal logger.
  void setLogger(BaseLogger logger) => _logger = logger;

  /// Returns the [count] last lines of [filename].
  /// [reversed]: true: the lines in the result are in reversed order (last line
  /// is first)
  List<String> tail(String filename, int count, {reversed = false}) {
    var rc = <String>[];
    // Does not work:
    // File(filename)
    //     .openRead()
    //     .map(utf8.decode)
    //     .transform(LineSplitter())
    //     .forEach((line) {
    //   rc.add(line);
    //   if (rc.length > count + 1) {
    //     rc.removeAt(0);
    //   }
    // });
    // if (rc.length == count) {
    //   if (rc[count].isEmpty) {
    //     rc.removeLast();
    //   } else {
    //     rc.removeAt(0);
    //   }
    // }
    rc = fileAsList(filename);
    if (rc.length > count) {
      rc.removeRange(0, rc.length - count);
    }
    if (reversed) {
      rc = rc.reversed.toList();
    }
    return rc;
  }

  /// Returns the name of a directory inside the temp directory.
  /// The directory will be created if it does not exist.
  /// [node]: name of the directory
  /// [logger]: if given the creation of directory will be logged
  /// [subDirs]: if given: one or more nested directories, e.g. 'unittest/mytest'
  /// node is laying inside [subDirs]
  String tempDirectory(String node, {String? subDirs}) {
    var rc = subDirs == null
        ? package_path.join(tempDir, node)
        : package_path.join(tempDir, subDirs, node);
    ensureDirectory(rc);
    return rc;
  }

  /// Returns the name of a file inside the temp directory.
  /// If [subDirs] are given, these [subDirs] will be created if not existing.
  /// [node]: name of the returned filename (without path). If [node] endswith '*': a unique node is chosen
  /// [logger]: if given the creation of directory will be logged
  /// [subDirs]: if given: one or more nested directories, e.g. 'unittest/mytest'
  /// node is laying inside [subDirs]
  String tempFile(String node, {String? subDirs, String? extension}) {
    final baseDir =
        subDirs == null ? tempDir : package_path.join(tempDir, subDirs);
    ensureDirectory(baseDir);
    var rc = baseDir.endsWith(sep) ? baseDir : baseDir + sep;
    if (!node.endsWith('*')) {
      rc += node;
    } else {
      rc += node.substring(0, node.length - 1) +
          '.' +
          DateTime.now().millisecondsSinceEpoch.toString();
    }
    if (extension != null) {
      rc += extension;
    }
    return rc;
  }

  /// Writes a [content] into a file named [filename].
  /// [filename]: the name of the file with path
  /// [content]: the file content. If null: '' will be used
  /// [date]: null or the modification date as DateTime instance
  /// [dateAsString]: null or the modification date as string, e.g. '2019.2.3-4:33:55'
  /// [asTransaction]: true: the file will be written to another filename and renamed afterwords
  /// [mode]: null or the access rights of the file
  void toFile(String filename, String? content,
      {DateTime? date,
      String? dateAsString,
      bool asTransaction = false,
      bool inline = false,
      int? mode,
      bool createDirectory = false}) {
    final target = asTransaction
        ? package_path.dirname(filename) +
            '~' +
            package_path.basename(filename) +
            '~'
        : filename;
    var file = File(target);
    content ??= '';
    if (!inline || !file.existsSync() || Platform.isLinux) {
      // writeAsStringsSync() writes "inline" under linux:
      try {
        file.writeAsStringSync(content, flush: true);
      } on FileSystemException catch (exc) {
        if (!createDirectory) {
          _logger.error('$exc');
        } else {
          final parent = package_path.dirname(filename);
          if (!Directory(parent).existsSync()) {
            ensureDirectory(parent);
          } else {
            _logger.error('$exc');
          }
        }
      }
    } else {
      final ioSink = file.openWrite();
      ioSink.write(content);
      ioSink.close();
    }
    if (mode != null) {
      chmod(target, mode);
    }

    if (asTransaction) {
      final file2 = File(filename);
      if (file2.existsSync()) {
        try {
          file2.deleteSync();
        } catch (e) {
          _logger.error('cannot remove $filename');
        }
      }
      try {
        _logger.log('renaming $target -> $filename', LEVEL_FINE);
        File(target).renameSync(filename);
      } catch (e) {
        _logger.error('cannot rename $target => $filename');
      }
    }
    if (dateAsString != null) {
      date = string_utils.stringToDateTime(dateAsString);
    }
    if (date != null) {
      File(filename).setLastModifiedSync(date);
    }
  }

  /// Initializes the singleton.
  static FileSync initialize(BaseLogger logger) {
    return _instance = FileSync._internal(logger);
  }
}
