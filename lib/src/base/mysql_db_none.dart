import 'package:dart_bones/dart_bones.dart';

class DbException implements Exception {
  String message;
  String sql;
  List? params;
  String origin;

  DbException(this.message, this.sql, this.params, this.origin);

  @override
  String toString() {
    final buffer = StringBuffer();
    if (message.isNotEmpty) {
      buffer.writeln(message);
    }
    if (origin.isNotEmpty) {
      buffer.writeln(origin);
    }
    if (sql.isNotEmpty) {
      buffer.writeln(sql);
    }
    if (params != null) {
      buffer.writeln(params.toString());
    }
    return buffer.toString().trimRight();
  }
}

class MySqlDb {
  bool throwOnError = false;
  String? dbName;
  String? dbUser;
  String? dbCode;
  String? dbHost;
  int? dbPort;
  bool? hasConnection;

  /// Constructor
  MySqlDb(
      {required String dbName,
      required String dbUser,
      required String dbCode,
      String dbHost = 'localhost',
      int dbPort = 3306,
      int traceDataLength = 80,
      String sqlTracePrefix = '',
      int timeout = 30,
      required BaseLogger logger}) {
    throw UnsupportedError('not implemented: MysqlDb()');
  }

  /// Constructor. Builds the instance from the [configuration] data.
  MySqlDb.fromConfiguration(BaseConfiguration configuration, BaseLogger logger,
      {String section = 'db'}) {
    throw UnsupportedError('not implemented: MysqlDb.fromConfiguration()');
  }
  void close() {
    throw UnsupportedError('not implemented: MySqlDb.close()');
  }

  Future<bool> connect({bool? throwOnError}) async {
    throw UnsupportedError('not implemented: MySqlDb.connect()');
  }

  Future<bool> execute(String sql,
      {List<dynamic>? params, bool? throwOnError}) async {
    throw UnsupportedError('not implemented: MySqlDb.execute()');
  }

  Future<dynamic> insertRaw(String sql,
      {List<dynamic>? params, bool? throwOnError}) async {
    throw UnsupportedError('not implemented: MySqlDb.execute()');
  }

  Future<int?> readOneInt(String sql,
      {List<dynamic>? params, nullAllowed = false, bool? throwOnError}) async {
    throw UnsupportedError('not implemented: MySqlDb.readOneInt()');
  }

  static dynamic convertNamedParams(
      {required String sql,
      required Map<String, dynamic> mapParams,
      required BaseLogger logger,
      bool ignoreError = false}) {
    throw UnsupportedError('not implemented: MySqlDb.convertNamedParams()');
  }

  Future<bool> readAndExecute(
      String sql, List<dynamic> params, dynamic onSingleRow) async {
    throw UnsupportedError('not implemented: MySqlDb.readAndExecute()');
  }
}

enum MysqlType {
  undef,
  int,
  text,
  timestamp,
  date,
  datetime,
  time,
  double,
  decimal,
  blob,
  bit,
  bool,
  year,
}
