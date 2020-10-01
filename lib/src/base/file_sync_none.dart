import 'package:sprintf/sprintf.dart';

/// Implements static functions for files and directories in the sync variant.
class FileSync {
  static final sep = '/';
  static final currentDirSep = './';

  /// Returns the extension of the [path].
  /// The extension is the part behind the last '.'.
  /// If the only '.' is at the top, the result is '' otherwise the the last part with '.'.
  static String extensionOf(String path) {
    var rc = '';
    final ix = path.lastIndexOf('.');
    final ixSlash = path.lastIndexOf(sep);
    if (ix > 0 && (ixSlash < 0 || ix > ixSlash + 1)) {
      rc = path.substring(ix);
    }
    return rc;
  }

  /// Returns the extension of the [path].
  /// The extension is the part behind the last '.'.
  /// If the only '.' is at the top, the result is '' otherwise the the last part with '.'.
  static String filenameOf(String path) {
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

  /// Joins parts to a combined path.
  /// [first]: first part
  /// [second]: second part
  /// [third]: third part
  static String joinPaths(String first, String second, [String third]) {
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
      {String appendix, List<String> appendixes, String nativeSep}) {
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
  static String nodeOf(String path) {
    final ix = path.lastIndexOf(sep);
    final rc = ix < 0 ? path : path.substring(ix + 1);
    return rc;
  }

  /// Returns the parent directory of the [path].
  /// Example: dirname('abc/def.txt') == 'abc/'
  static String parentOf(String path) {
    final ix = path.lastIndexOf(sep);
    final rc = ix < 0 ? '' : path.substring(0, ix + 1);
    return rc;
  }

}
