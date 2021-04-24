import 'package:sprintf/sprintf.dart';

import 'base_logger.dart';
import 'bones_globals.dart';

/// Implements static functions for files and directories in the sync variant.
class FileSync {
  static final sep = '/';
  static final currentDirSep = './';

  /// the singleton instance
  static FileSync? _instance;
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
    if (logger != null) {
      rc._logger = logger;
    }
    return rc;
  }

  /// Internal constructor
  FileSync._internal(this._logger);

  void ensureDirectory(String path,
      {int? mode, int? owner, int? group, bool clear = false}) {
    _logger.error('unsupported: ensureDirectory()');
    throw UnsupportedError('FileSync.ensureDirectory()');
  }

  void ensureDoesNotExist(String filename, {bool recursive = false}) {
    throw UnsupportedError('FileSync.tempDirectory()');
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

  String fileAsString(String filename) {
    throw UnsupportedError('FileSync.tempDirectory()');
  }

  /// Returns the extension of the [path].
  /// The extension is the part behind the last '.'.
  /// If the only '.' is at the top, the result is '' otherwise the the last part with '.'.
  /// deprecated: Use basename() from package path
  @deprecated
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

  String tempDirectory(String node, {String? subDirs}) {
    throw UnsupportedError('FileSync.tempDirectory()');
  }

  void toFile(String filename, String? content,
      {DateTime? date,
      String? dateAsString,
      bool asTransaction = false,
      bool inline = false,
      int? mode,
      bool createDirectory = false}) {
    throw UnsupportedError('FileSync.toFile()');
  }

  /// Returns a human readable string of a file [size], e.g. '2.389MB'.
  static String humanSize(int size) {
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

  static FileSync initialize(BaseLogger logger) {
    throw UnsupportedError('FileSync.initialize()');
  }

  /// Joins parts to a combined path.
  /// [first]: first part
  /// [second]: second part
  /// [third]: third part
  /// deprecated: Use join() from package path
  @deprecated
  static String joinPaths(String first, String second, [String? third]) {
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
  static String nativePath(String path,
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
  static String nodeOf(String path) {
    final ix = path.lastIndexOf(sep);
    final rc = ix < 0 ? path : path.substring(ix + 1);
    return rc;
  }

  /// Returns the parent directory of the [path].
  /// Example: dirname('abc/def.txt') == 'abc/'
  /// deprecated: Use dirname() from package path
  @deprecated
  static String parentOf(String path) {
    final ix = path.lastIndexOf(sep);
    final rc = ix < 0 ? '' : path.substring(0, ix + 1);
    return rc;
  }
}
