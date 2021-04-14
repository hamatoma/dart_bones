import 'dart:async';

import 'package:dart_bones/dart_bones.dart';
import 'package:meta/meta.dart';
import 'package:mysql1/mysql1.dart';

typedef CallbackOnSingleRow = Future<bool> Function(List<dynamic> row);

class ColumnInfo {
  final String name;
  final MysqlType type;
  final String typeName;
  final int size;
  final String options;
  final String defaultValue;
  ColumnInfo(this.name,
      {this.type, this.typeName, this.size, this.options, this.defaultValue});
}

class DbException implements Exception {
  String message;
  String sql;
  List params;
  String origin;

  DbException(this.message, this.sql, this.params, this.origin);

  @override
  String toString() {
    final buffer = StringBuffer();
    if (message != null) {
      buffer.writeln(message);
    }
    if (origin != null) {
      buffer.writeln(origin);
    }
    if (sql != null) {
      buffer.writeln(sql);
    }
    if (params != null) {
      buffer.writeln(params.toString());
    }
    return buffer.toString().trimRight();
  }
}

class MySqlDb {
  static final _regExpTextSize = RegExp(r'^\w+\((\d+)\)');
  static const _typePrefixes = <String>[
    'int',
    'dec',
    'text',
    'timestamp',
    'datetime',
    'date',
    'char',
    'varchar',
    'tinytext',
    'double',
    'decimal',
    'blob',
    'bit',
    'bool',
    'tinyint',
    'smallint',
    'mediumint',
    'bigint',
    'float',
    'time',
    'year',
  ];
  static const _typeOfPrefix = <MysqlType>[
    MysqlType.int,
    MysqlType.decimal,
    MysqlType.text,
    MysqlType.timestamp,
    MysqlType.datetime,
    MysqlType.date,
    MysqlType.text,
    MysqlType.text,
    MysqlType.text,
    MysqlType.double,
    MysqlType.decimal,
    MysqlType.blob,
    MysqlType.bit,
    MysqlType.bool,
    MysqlType.int,
    MysqlType.int,
    MysqlType.int,
    MysqlType.int,
    MysqlType.double,
    MysqlType.time,
    MysqlType.year,
  ];
  String dbName;
  String dbUser;
  String dbCode;
  String dbHost;
  int dbPort;
  int timeout;
  int traceDataLength;
  String sqlTracePrefix;
  bool _throwOnError = false;
  Results _lastResults;

  MySqlConnection _dbConnection;

  final BaseLogger logger;

  List<String> tables;

  /// Constructor
  MySqlDb(
      {@required this.dbName,
      @required this.dbUser,
      @required this.dbCode,
      this.dbHost = 'localhost',
      this.dbPort = 3306,
      this.traceDataLength = 80,
      this.sqlTracePrefix,
      this.timeout = 30,
      @required this.logger});

  /// Constructor. Builds the instance from the [configuration] data.
  MySqlDb.fromConfiguration(BaseConfiguration configuration, this.logger,
      {String section = 'db'}) {
    dbName = configuration.asString('db', section: section);
    dbUser = configuration.asString('user', section: section);
    dbCode = configuration.asString('code', section: section);
    dbHost = configuration.asString('host',
        section: section, defaultValue: 'localhost');
    dbPort = configuration.asInt('port', section: section, defaultValue: 3306);
    traceDataLength = configuration.asInt('traceDataLength',
        section: section, defaultValue: 80);
    timeout =
        configuration.asInt('timeout', section: section, defaultValue: 30);
  }

  bool get hasConnection => _dbConnection != null;

  Results get lastResults => _lastResults;

  set throwOnError(bool value) => _throwOnError = value;

  /// Returns the insert statement representing the [result] in the [table].
  /// [excluded]: a list of column names: they will be ignored.
  String buildInsertFromResult(String table, Results result,
      {List<String> excluded}) {
    final sql = StringBuffer();
    sql.write('insert into ');
    sql.write(table);
    sql.write('(');
    var count = 0;
    for (var field in result.fields) {
      final name = field.name;
      if (excluded == null || !excluded.contains(name)) {
        if (++count > 1) {
          sql.write(',');
        }
        sql.write(name);
      }
    }
    sql.write(') values (');
    for (var ix = 0; ix < count; ix++) {
      if (ix > 0) {
        sql.write(',');
      }
      sql.write('?');
    }
    sql.write(');');
    return sql.toString();
  }

  /// Frees the resources.
  void close() {
    if (_dbConnection != null) {
      _dbConnection.close();
      _dbConnection = null;
    }
  }

  /// Builds the connection to the MYSQL database.
  /// [throwOnError]: null: use _throwOnError true: if an error occurs
  //  an exception is thrown. false: return value respects an error
  /// return: true: success
  Future<bool> connect({bool throwOnError}) async {
    bool rc;
    var reported = false;
    try {
      logger.log('connect to $dbHost:$dbPort-$dbName:$dbUser', LEVEL_SUMMERY);
      final conn = _dbConnection = await MySqlConnection.connect(
          ConnectionSettings(
              host: dbHost,
              port: dbPort,
              user: dbUser,
              db: dbName,
              password: dbCode,
              timeout: timeout == null ? null : Duration(seconds: timeout)));
      if (conn == null) {
        final msg = 'cannot connect: db: $dbName user: $dbUser';
        if (throwOnError ?? _throwOnError) {
          throw DbException(msg, null, null, null);
        }
      } else {
        logger.log('connection success', LEVEL_SUMMERY);
        _dbConnection = conn;
      }
      rc = conn != null;
    } catch (exc, stack) {
      final msg = 'cannot connect (2): db: $dbName user: $dbUser';
      logger.error(msg);
      reported = true;
      if (throwOnError ?? _throwOnError) {
        throw DbException(msg, null, null, '$exc\n$stack');
      }
      rc = false;
    }
    if (!reported && _dbConnection == null) {
      logger.error('cannot connect (3): db: $dbName user: $dbUser');
    }
    return rc;
  }

  /// Executes an DELETE statement.
  /// [sql] the sql statement, e.g. 'insert into users (user_name) values (?);'
  /// [params] null or the positional parameters, e.g. ['john']
  /// [throwOnError]: null: use _throwOnError true: if an error occurs
  /// an exception is thrown. false: return value respects an error
  /// return: null: failure otherwise: the Results instance
  Future<Results> deleteRaw(String sql,
      {List<dynamic> params, bool throwOnError}) async {
    logger.logLevel >= LEVEL_LOOP && traceSql(sql, params);
    try {
      _lastResults = await _dbConnection.query(sql, params);
    } catch (error) {
      _lastResults = null;
      logger.error('cannot delete: $error\n$sql');
      if (throwOnError ?? _throwOnError) {
        throw DbException('deleteRaw()', sql, params, error.toString());
      }
    }
    return _lastResults;
  }

  /// Executes a SQL statement.
  /// [sql] the sql statement, e.g. 'drop table test_db;'
  /// [params] null or the positional parameters of the statement (given as '?')
  /// [throwOnError]: null: use _throwOnError true: if an error occurs
  /// an exception is thrown. false: return value respects an error
  /// return: true: success
  Future<bool> execute(String sql,
      {List<dynamic> params, bool throwOnError}) async {
    var rc = true;
    logger.logLevel >= LEVEL_LOOP && traceSql(sql, params);
    _lastResults = null;
    try {
      final results = await _dbConnection.query(sql, params);
      _lastResults = results;
    } catch (error) {
      logger.error('cannot execute: $error\n$sql');
      _lastResults = null;
      rc = false;
      if (throwOnError ?? _throwOnError) {
        throw DbException('execute()', sql, params, error.toString());
      }
    }
    return rc;
  }

  /// Returns all columns of a [table].
  Future<Map<String, ColumnInfo>> getColumns(String table) async {
    final rc = <String, ColumnInfo>{};
    final records = await readAllAsLists('show columns in $table;');
    if (records != null && records.isNotEmpty) {
      // Find the first key:
      records.forEach((column) {
        final name = column['Field'];
        final typeName = column['Type'].toString();
        final type = getType(typeName);
        var size;
        if (type == MysqlType.text) {
          var match = _regExpTextSize.firstMatch(typeName);
          if (match != null) {
            size = int.parse(match.group(1));
          } else {
            if (typeName.startsWith('small')) {
              size = 255;
            } else if (typeName.startsWith('text')) {
              size = 65535;
            } else if (typeName.startsWith('medium')) {
              size = 16777215;
            } else if (typeName.startsWith('long')) {
              size = 4294967295;
            }
          }
        }
        var options = column['Key'].contains('PRI') ? 'primary' : '';
        options += column['Null'] == 'YES' ? ' null' : ' notnull';
        if (column['Extra'].contains('auto_increment')) {
          options += ' auto_increment';
        }
        rc[name] = ColumnInfo(
          name,
          type: type,
          typeName: typeName,
          size: size,
          options: options,
          defaultValue: column['Default'].toString(),
        );
      });
    }
    return rc;
  }

  /// Returns all table names of the database.
  Future<List<String>> getTables() async {
    var rc = <String>[];
    final records = await readAllAsLists('show tables;');
    if (records != null && records.isNotEmpty) {
      // Find the first key:
      records.forEach((table) {
        table.forEach((item) => rc.add(item));
      });
      tables ??= rc;
    }
    return rc;
  }

  /// Returns the mysql type of a string given by the column "Type" of "show columns".
  MysqlType getType(String typeName) {
    var type = MysqlType.undef;
    assert(_typePrefixes.length == _typeOfPrefix.length);
    for (var ix = 0; ix < _typeOfPrefix.length; ix++) {
      if (typeName.startsWith(_typePrefixes[ix])) {
        type = _typeOfPrefix[ix];
        break;
      }
    }
    return type;
  }

  /// Tests whether the database has a table named [name].
  /// [forceUpdate]: false: the tables are read only if needed. true: the
  /// tables are read always.
  Future<bool> hasTable(String name, {bool forceUpdate = false}) async {
    bool rc;
    if (forceUpdate || tables == null) {
      await getTables();
    }
    rc = tables.contains(name);
    return rc;
  }

  /// Executes an INSERT statement for one record and returns the primary key.
  /// [sql] the sql statement, e.g. 'insert into users (user_name) values (?);'
  /// [params] null or the positional parameters, e.g. ['john']
  /// [throwOnError]: null: use _throwOnError true: if an error occurs
  //  an exception is thrown. false: return value respects an error
  /// return: 0: failure otherwise: the primary key of the new record
  Future<int> insertOne(String sql,
      {List<dynamic> params, bool throwOnError}) async {
    final results =
        await insertRaw(sql, params: params, throwOnError: throwOnError);
    final rc = results == null ? null : results.insertId;
    if (results != null && results.affectedRows != 1) {
      logger.error('insert failed:\n$sql');
      if (throwOnError ?? _throwOnError) {
        throw DbException('insertOne()', sql, params,
            'affected rows: ${results.affectedRows} instead of 1');
      }
    }
    return rc;
  }

  /// Executes an INSERT statement.
  /// [sql] the sql statement, e.g. 'insert into users (user_name) values (?);'
  /// [params] null or the positional parameters, e.g. ['john']
  /// [throwOnError]: null: use _throwOnError true: if an error occurs
  /// an exception is thrown. false: return value respects an error
  /// return: null: failure otherwise: the Results instance
  Future<Results> insertRaw(String sql,
      {List<dynamic> params, bool throwOnError}) async {
    logger.logLevel >= LEVEL_LOOP && traceSql(sql, params);
    try {
      _lastResults = await _dbConnection.query(sql, params);
    } catch (error) {
      _lastResults = null;
      logger.error('insert failed: $error\n$sql');
      if (throwOnError ?? _throwOnError) {
        throw DbException('insertRaw()', sql, params, error.toString());
      }
    }
    return _lastResults;
  }

  /// Returns all records defined by a select statement given by [sql]
  /// and positional parameters given by [params].
  /// Example: readAll('select * from users where user_id=?', params: [1]);
  /// [throwOnError]: null: use _throwOnError true: if an error occurs
  /// an exception is thrown. false: return value respects an error
  /// return: null: failure otherwise: the Results instance
  Future<Results> readAll(String sql,
      {List<dynamic> params, bool throwOnError}) async {
    logger.logLevel >= LEVEL_LOOP && traceSql(sql, params);
    try {
      _lastResults = await _dbConnection.query(sql, params);
    } catch (error) {
      _lastResults = null;
      logger.error('readAll failed: $error\n$sql');
      if (throwOnError ?? _throwOnError) {
        throw DbException('readAll()', sql, params, error.toString());
      }
    }
    return _lastResults;
  }

  /// Selects some records via [sql] and positional [params] and returns a list
  /// of records as lists.
  /// [throwOnError]: null: use _throwOnError true: if an error occurs
  /// an exception is thrown. false: return value respects an error
  /// return: null: failure otherwise: a list of db records
  Future<List<dynamic>> readAllAsLists(String sql,
      {List<dynamic> params, bool throwOnError}) async {
    var rows = [];
    final results =
        await readAll(sql, params: params, throwOnError: throwOnError);
    if (results == null) {
      rows = null;
    } else {
      for (var row in results) {
        rows.add(row);
      }
    }
    logger.logLevel >= LEVEL_LOOP && logger.log('rows: ${rows?.length}');
    return rows;
  }

  /// Selects some records via [sql] and positional [params] and returns a list
  /// of record maps.
  /// [throwOnError]: null: use _throwOnError true: if an error occurs
  /// an exception is thrown. false: return value respects an error
  /// return: null: failure otherwise: a list of db records
  Future<List<Map<String, dynamic>>> readAllAsMaps(String sql,
      {List<dynamic> params, bool throwOnError}) async {
    var rows = <Map<String, dynamic>>[];
    final results =
        await readAll(sql, params: params, throwOnError: throwOnError);
    if (results == null) {
      rows = null;
    } else {
      for (var row in results) {
        rows.add(row.fields);
      }
    }
    logger.logLevel >= LEVEL_LOOP && logger.log('rows: ${rows?.length}');
    return rows;
  }

  /// Reads all record selected by a [sql] statement with parameters given
  /// in [params] and call for each row a callback [onSingleRow].
  /// return: true: success
  Future<bool> readAndExecute(
      String sql, List<dynamic> params, CallbackOnSingleRow onSingleRow) async {
    var rc = true;
    logger.logLevel >= LEVEL_LOOP && traceSql(sql, params);
    // _lastResults = null;
    try {
      _lastResults = await _dbConnection.query(sql, params);
      for (var row in _lastResults) {
        await onSingleRow(row);
      }
    } catch (error) {
      logger.error('readAndExecute(): $error\n$sql');
      rc = false;
    }
    return rc;
  }

  /// Selects one record via [sql] and positional [params] and returns a record
  /// [throwOnError]: null: use _throwOnError true: if an error occurs
  /// an exception is thrown. false: return value respects an error
  /// map.
  /// return: null: failure otherwise: the record of the database
  Future<Map<String, dynamic>> readOneAsMap(String sql,
      {List<dynamic> params, bool throwOnError}) async {
    Map<String, dynamic> rc;
    var found = false;
    final results = await readAll(sql, params: params);
    for (var row in results) {
      found = true;
      if (rc == null) {
        rc = row.fields;
      } else {
        logger.error('read failed:\n$sql');
        if (throwOnError ?? _throwOnError) {
          throw DbException(
              'readOneAsMap()', sql, params, 'more than one record');
        }
        rc = null;
      }
    }
    if (!found) {
      logger.error('no record found:\n$sql');
      if (throwOnError ?? _throwOnError) {
        throw DbException('readOneAsMap()', sql, params, 'no record');
      }
      rc = null;
    }
    logger.logLevel >= LEVEL_LOOP &&
        logger.log('row items: ${rc?.keys?.length}');
    return rc;
  }

  /// Selects one value via [sql] and positional [params] and returns the value
  /// as integer.
  /// [nullAllowed]: false: to find no record is an error
  /// [throwOnError]: null: use _throwOnError true: if an error occurs
  /// an exception is thrown. false: return value respects an error
  /// return: null: failure otherwise: the field value
  Future<int> readOneInt(String sql,
      {List<dynamic> params, nullAllowed = false, bool throwOnError}) async {
    int rc;
    var found = false;
    final results =
        await readAll(sql, params: params, throwOnError: throwOnError);
    if (results != null) {
      for (var row in results) {
        found = true;
        if (rc == null) {
          if (row.values.length > 1) {
            logger.error('more than one record found:\n$sql');
            if (throwOnError ?? _throwOnError) {
              throw DbException(
                  'readOneInt()', sql, params, 'more than one value');
            }
            break;
          }
          if (row.values[0] is int) {
            rc = row.values[0];
          } else {
            logger.error('not an integer:\n$sql');
            if (throwOnError ?? _throwOnError) {
              throw DbException('readOneInt()', sql, params,
                  'not an integer: ${row.values[0]}');
            }
            break;
          }
        } else {
          logger.error('more than one record found:\n$sql');
          if (throwOnError ?? _throwOnError) {
            throw DbException(
                'readOneInt()', sql, params, 'more than one record');
          }
          break;
        }
      }
      if (!found && !nullAllowed) {
        logger.error('no record found:\n$sql');
        if (throwOnError ?? _throwOnError) {
          throw DbException('readOneInt()', sql, params, 'no record found');
        }
        rc = null;
      }
    }
    logger.log('result: $rc', LEVEL_LOOP);
    return rc;
  }

  /// Selects one value via [sql] and positional [params] and returns the value
  /// as string.
  /// [nullAllowed]: false: to find no record is an error
  /// [throwOnError]: null: use _throwOnError true: if an error occurs
  /// an exception is thrown. false: return value respects an error
  /// return: null: error otherwise: the field value
  Future<String> readOneString(String sql,
      {List<dynamic> params, nullAllowed = false, bool throwOnError}) async {
    String rc;
    final results = await readAll(sql, params: params);
    var found = false;
    if (results != null) {
      for (var row in results) {
        found = true;
        if (rc == null) {
          rc = row.values[0].toString();
        } else {
          logger.error('more than one record found:\n$sql');
          if (throwOnError ?? _throwOnError) {
            throw DbException(
                'readOneString()', sql, params, 'more than one record');
          }
          break;
        }
      }
    }
    if (!found && !nullAllowed) {
      logger.error('no record found:\n$sql');
      if (throwOnError ?? _throwOnError) {
        throw DbException('readOneString()', sql, params, 'no record');
      }
    }
    logger.log('result: $rc', LEVEL_LOOP);
    return rc;
  }

  /// Writes the [sql] string with its parameters to the log, limited by [traceDataLength].
  bool traceSql(String sql, List<dynamic> params) {
    String msg;
    if (sql == null) {
      msg = 'null';
    } else {
      msg = StringUtils.limitString(sql, traceDataLength);
    }
    if ((msg.startsWith('SELECT') || msg.startsWith('select')) &&
        msg.length >= traceDataLength) {
      var ix1 = sql.indexOf('WHERE');
      if (ix1 < 0) {
        ix1 = sql.indexOf('where');
      }
      if (ix1 > 0) {
        final limit = (traceDataLength / 2).round();
        msg = StringUtils.limitString(sql.substring(0, ix1), limit);
        if (!msg.endsWith('.')) {
          msg += '..';
        }
        msg += '\n' +
            StringUtils.limitString(
                sql.substring(ix1), traceDataLength - msg.length);
      }
    }
    logger.log((sqlTracePrefix ?? '') + msg);
    if (params != null) {
      final buffer = StringBuffer('params: ');
      var ix = -1;
      while (++ix < params.length && buffer.length < traceDataLength) {
        if (buffer.length > 8) {
          buffer.write('|');
        }
        buffer.write('${params[ix]}');
      }
      logger.log(StringUtils.limitString(buffer.toString(), traceDataLength));
    }
    return true;
  }

  /// Executes an UPDATE statement for one record.
  /// [sql] the sql statement, e.g. 'update users set user_name=? where user_id=?;'
  /// [params] null or the positional parameters, e.g. ['john']
  /// [throwOnError]: null: use _throwOnError true: if an error occurs
  /// an exception is thrown. false: return value respects an error
  /// return: true: success
  Future<bool> updateOne(String sql,
      {List<dynamic> params, bool throwOnError}) async {
    var rc = true;
    final affected =
        await updateRaw(sql, params: params, throwOnError: throwOnError);
    if (affected != 1) {
      final msg = 'affected rows: $affected instead of 1';
      logger.error('$msg\n$sql');
      if (throwOnError ?? _throwOnError) {
        throw DbException('updateOne()', sql, params, msg);
      }
      rc = false;
    }
    return rc;
  }

  /// Updates a record. If this record does not exists it will be inserted.
  /// Note: this is with good performance if many updates were done ("normal case").
  /// [table]: the table to inspect
  /// [data]: data[<field_name>] = <field_value>
  /// [keys]: a list of field names which are all together unique to a record.
  /// [throwOnError]: null: use _throwOnError true: if an error occurs
  /// an exception is thrown. false: return value respects an error
  /// they will identify the record.
  void updateOrInsert(
      String table, Map<String, dynamic> data, List<String> keys,
      {bool throwOnError}) async {
    var sql = StringBuffer();
    sql.write('UPDATE ');
    sql.write(table);
    sql.write(' SET ');
    var params = [];
    var first = true;
    for (var key in data.keys) {
      if (keys.contains(key)) {
        continue;
      }
      if (first) {
        first = false;
      } else {
        sql.write(',');
      }
      sql.write(key);
      sql.write('=?');
      params.add(data[key]);
    }
    var condition = '';
    for (var key in keys) {
      if (condition.isNotEmpty) {
        condition += ' AND ';
      }
      params.add(data[key]);
      condition += '$key=?';
    }
    sql.write(' WHERE ');
    sql.write(condition);
    sql.write(';');
    final sql2 = sql.toString();
    final affected =
        await updateRaw(sql2, params: params, throwOnError: throwOnError);
    if (affected == 0) {
      params = [];
      sql.clear();
      sql.write('INSERT INTO ');
      sql.write(table);
      sql.write(' (');
      var first = true;
      data.forEach((String key, value) {
        if (first) {
          first = false;
        } else {
          sql.write(',');
        }
        sql.write(key);
        params.add(value);
      });
      sql.write(') values (');
      for (var ix = 0; ix < data.length; ix++) {
        if (ix > 0) {
          sql.write(',?');
        } else {
          sql.write('?');
        }
      }
      sql.write(');');
      await insertOne(sql.toString(),
          params: params, throwOnError: throwOnError);
    }
  }

  /// Executes an UPDATE statement and returns the number of affected rows.
  /// [sql] the sql statement, e.g. "update users changed=null where user_name=?;"
  /// [params] null or the positional parameters, e.g. ['john']
  /// [throwOnError]: null: use _throwOnError true: if an error occurs
  /// an exception is thrown. false: return value respects an error
  /// return: null: failure otherwise: the number of affected rows
  Future<int> updateRaw(String sql,
      {List<dynamic> params, bool throwOnError}) async {
    logger.logLevel >= LEVEL_LOOP && traceSql(sql, params);
    _lastResults = null;
    try {
      final results = await _dbConnection.query(sql, params);
      _lastResults = results;
    } catch (error) {
      logger.error('cannot update: $error\n$sql');
      _lastResults = null;
      if (throwOnError ?? _throwOnError) {
        throw DbException('updateRaw()', sql, params, error.toString());
      }
    }
    final rc = _lastResults?.affectedRows;
    logger.log('affected: $rc', LEVEL_LOOP);
    return rc;
  }

  /// Converts a database result [value] into a string.
  static String asString(dynamic value) {
    var rc;
    if (value is String) {
      rc = value;
    } else if (value is int) {
      rc = value.toString();
    } else if (value is DateTime) {
      rc = StringUtils.dateToString('Y-m-d H:i:s', value);
    } else {
      rc = '$value';
    }
    return rc;
  }

  /// Converts the [sql] statement with named parameters to a SQL statement with
  /// positional parameters and build the parameter list from a [mapParams].
  /// return: null: error found otherwise: the changed SQL and the parameter list
  static SqlAndParamList convertNamedParams(
      {@required String sql,
      @required Map<String, dynamic> mapParams,
      @required BaseLogger logger,
      bool ignoreError = false}) {
    SqlAndParamList rc;
    final listParams = [];
    final regExp = RegExp(r':\w+');
    var sql2 = sql;
    for (var matcher in regExp.allMatches(sql)) {
      final name = matcher.group(0);
      if (mapParams.containsKey(name)) {
        listParams.add(mapParams[name]);
        sql2 = sql2.replaceFirst(name, '?');
      } else {
        final msg =
            '$name not found in sql: ${StringUtils.limitString(sql, 80)}';
        if (ignoreError) {
          logger.log(
              '$name not found in sql: ${StringUtils.limitString(sql, 80)}',
              LEVEL_DETAIL);
        } else {
          logger.error(msg);
          sql2 = null;
          break;
        }
      }
    }
    if (sql2 != null) {
      rc = SqlAndParamList(sql2, listParams);
    }
    return rc;
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

class SqlAndParamList {
  String sql;
  List<dynamic> params;

  SqlAndParamList(this.sql, this.params);
}
