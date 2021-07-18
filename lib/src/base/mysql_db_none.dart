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
  int timeout = 0;
  String? dbName;
  String? dbUser;
  String? dbCode;
  String? dbHost;
  int? dbPort;
  bool hasConnection = false;

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

  Future<bool> hasTable(String name, {bool forceUpdate = false}) async {
    throw UnsupportedError('not implemented: MysqlDb.hasTable()');
  }

  Future<int> insertOne(String sql,
      {List<dynamic>? params, bool? throwOnError}) async {
    throw UnsupportedError('not implemented: MySqlDb.insertOne()');
  }

  Future<dynamic> insertRaw(String sql,
      {List<dynamic>? params, bool? throwOnError}) async {
    throw UnsupportedError('not implemented: MySqlDb.insertRaw()');
  }

  Future<dynamic> readAll(String sql,
      {List<dynamic>? params, bool? throwOnError}) async {
    throw UnsupportedError('not implemented: MySqlDb.readAll()');
  }

  Future<List<dynamic>?> readAllAsLists(String sql,
      {List<dynamic>? params, bool? throwOnError}) async {
    throw UnsupportedError('not implemented: MySqlDb.readAllAsLists()');
  }

  Future<bool> readAndExecute(
      String sql, List<dynamic> params, dynamic onSingleRow) async {
    throw UnsupportedError('not implemented: MySqlDb.readAndExecute()');
  }

  Future<Map<String, dynamic>?> readOneAsMap(String sql,
      {List<dynamic>? params, bool? throwOnError}) async {
    throw UnsupportedError('not implemented: MySqlDb.readOneAsMap');
  }

  Future<int?> readOneInt(String sql,
      {List<dynamic>? params, nullAllowed = false, bool? throwOnError}) async {
    throw UnsupportedError('not implemented: MySqlDb.readOneInt()');
  }

  Future<String?> readOneString(String sql,
      {List<dynamic>? params, nullAllowed = false, bool? throwOnError}) async {
    throw UnsupportedError('not implemented: MySqlDb.readOneString()');
  }

  Future<bool> updateOne(String sql,
      {List<dynamic>? params, bool? throwOnError}) async {
    throw UnsupportedError('not implemented: MySqlDb.updateOne()');
  }

  Future<int?> updateRaw(String sql,
      {List<dynamic>? params, bool? throwOnError}) async {
    throw UnsupportedError('not implemented: MySqlDb.updateRaw()');
  }

  static dynamic convertNamedParams(
      {required String sql,
      required Map<String, dynamic> mapParams,
      required BaseLogger logger,
      bool ignoreError = false}) {
    throw UnsupportedError('not implemented: MySqlDb.convertNamedParams()');
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
