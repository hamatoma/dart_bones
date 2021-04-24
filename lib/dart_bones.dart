/// Helper definitions for Dart programming.

library dart_bones;

export 'src/base/base_configuration.dart';
export 'src/base/memory_logger.dart';
export 'src/base/base_logger.dart';
export 'src/base/bones_globals.dart';
export 'src/base/configuration_none.dart' // Stub implementation
    if (dart.library.io) 'src/base/configuration_io.dart' // dart:io implementation
    if (dart.library.html) 'src/base/configuration_html.dart'; // dart:html implementation
export 'src/base/defines.dart';
export 'src/base/file_sync_none.dart' // default
    if (dart.library.io) 'src/base/file_sync_io.dart'; // dart:io implementation
export 'src/base/logger_none.dart' // Stub implementation
    if (dart.library.io) 'src/base/logger_io.dart' // dart:io implementation
    if (dart.library.html) 'src/base/logger_html.dart'; // dart:html implementation
export 'src/base/mysql_db_none.dart'
    if (dart.library.io) 'src/base/mysql_db_io.dart';
export 'src/base/os_service_none.dart'
    if (dart.library.io) 'src/base/os_service_io.dart';
export 'src/base/process_sync_none.dart'
    if (dart.library.io) 'src/base/process_sync_io.dart';
export 'src/base/string_utils.dart';
export 'src/base/validation.dart';
export 'src/base/crypto_base_engine.dart'
    if (dart.library.io) 'src/base/crypto_engine_io.dart';
export 'src/base/kiss_random.dart';
