import 'package:dart_bones/dart_bones.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

const SQL_ERROR = 'You have an error in your SQL syntax';

Future<MySqlDb> prepare(BaseLogger logger) async {
  final db = MySqlDb(
      dbName: 'dbunittest',
      dbUser: 'unittest',
      dbCode: 'TopSecret',
      dbHost: 'localhost',
      dbPort: 3306,
      sqlTracePrefix: 'sql: ',
      traceDataLength: 120,
      logger: logger);
  bool success;
  await db.connect();
  await db.execute('drop table if exists clouds;');
  success = await db.execute('''create table clouds(
  cloud_id int(10) unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  cloud_host int(10),
  cloud_name varchar(200) NOT NULL,
  cloud_total int(16),
  cloud_used int(16),
  cloud_free int(16)
  );''') >= 0;
  success = success && await db.execute('commit;') >= 0;
  success = success && await db.execute('drop table if exists groups;') >= 0;
  success = success && await db.execute('''create table groups(
  group_id int(10) unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  group_name varchar(200) NOT NULL,
  created datetime default now()
  );''') >= 0;
  success = success && await db.execute('commit;') >= 0;
  await db.insertRaw(
      "insert into groups (group_id, group_name) values (1, 'admin');");
  await db.insertRaw(
      "insert into groups (group_id, group_name) values (2, 'user');");
  success = success && await db.execute('commit;') >= 0;

  success = success && await db.execute('drop table if exists users;') >= 0;
  success = success && await db.execute('''create table users(
  user_id int(10) unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  group_id int(10) unsigned,
  user_name varchar(200) NOT NULL,
  created datetime default now(),
  user_info text
  );
  ''') >= 0;
  success = success && await db.execute('commit;') >= 0;
  await db.insertRaw(
      "insert into users (user_id, user_name, group_id) values (1, 'adam', 1);");
  await db.insertRaw(
      "insert into users (user_id, user_name, group_id) values (2, 'eve', 2);");
  await db.insertRaw(
      "insert into users (user_id, user_name, group_id) values (3, 'david', 2);");
  success = success && await db.execute('commit;') >= 0;
  expect(success, isTrue);
  final countUsers = await db.readOneInt('select count(*) from users;');
  logger.log('count users: $countUsers', LEVEL_SUMMERY);
  db.currentScriptName = 'test-script';
  return db;
}

void main() async {
  final logger = MemoryLogger(LEVEL_FINE);
  FileSync.initialize(logger);
  final fileSync = FileSync();
  var db;
  setUpAll(() async {
    db = await prepare(logger);
  });
  tearDownAll(() {
    db.close();
  });
  //group('common-because-not-concurrent', () {
  group('Basics', () {
    test('connect-fail', () async {
      logger.clear();
      logger.log('expecting: cannot connect(2)...');
      final db2 = MySqlDb(
          dbName: 'testdb',
          dbUser: 'test',
          dbCode: 'not-really-known',
          dbHost: 'localhost',
          dbPort: 3306,
          logger: logger);
      expect(await db2.connect(), isFalse);
      expect(logger.contains('cannot connect'), isTrue);
    });
    test('execute-fail-sql', () async {
      logger.log('expecting an error: wrong syntax');
      expect(await db.execute('show columns;'), -1);
    });
    test('fromConfiguration', () async {
      final config = BaseConfiguration({
        'db': {'db': 'testdb2', 'user': 'test2', 'code': 'X', 'port': 1234}
      }, logger);
      final db3 = MySqlDb.fromConfiguration(config, logger);
      db3.throwOnError = false;
      expect(db3.dbName, equals('testdb2'));
      expect(db3.dbUser, equals('test2'));
      expect(db3.dbCode, equals('X'));
      expect(db3.dbPort, equals(1234));
      expect(db3.hasConnection, isFalse);
      expect(await db3.execute('show tables;'), -1);
      db3.close();
    });
  });

  group('modifyX', () {
    test('insertOne', () async {
      final id = await db.insertOne(
          "insert into users (user_id, user_name, group_id) values (5, 'oscar', 2);");
      expect(await countOfUserId(db, 5), equals(1));
      expect(id, equals(5));
    });
    test('insertOne-fail-more', () async {
      try {
        await db.insertOne(
            "insert into users (user_id, user_name, group_id) values (6, 'rosa', 2), (7, 'tom', 2);",
            throwOnError: true);
        ;
        expect(false, isTrue);
      } on DbException catch (exc) {
        expect(exc.toString(), contains('affected'));
      }
      expect(
          await db.insertOne(
              "insert into users (user_id, user_name, group_id) values (6, 'rosa', 2), (7, 'tom', 2);"),
          0);
    });
    test('insertOne-fail-zero', () async {
      try {
        await db.insertOne(
            "insert into users (user_id, user_name, group_id) values (1, 'daniel', 2);",
            throwOnError: true);
        ;
        expect(false, isTrue);
      } on DbException catch (exc) {
        expect(exc.toString(), contains('Duplicate entry'));
      }
      expect(
          await db.insertOne(
              "insert into users (user_id, user_name, group_id) values (1, 'daniel', 2);"),
          0);
    });
    test('insertRaw', () async {
      final results = await db.insertRaw(
          "insert into users (user_id, user_name, group_id) values (10, 'jim', 2);");
      expect(await countOfUserId(db, 10), equals(1));
      expect(results.insertId, equals(10));
    });
    test('insertRaw-multiple', () async {
      final results = await db.insertRaw(
          "insert into users (user_id, user_name, group_id) values (11, 'judy', 2), (12, 'klaas', 2);");
      expect(await countOfUserId(db, 11), equals(1));
      expect(results.insertId, equals(12));
      expect(results.affectedRows, equals(2));
    });
    test('updateOne', () async {
      await db.updateOne('update users set group_id=? where user_id=?;',
          params: [1, 2]);
      final group = await db.readOneInt(
          'select group_id from users where user_id=?;',
          params: [1]);
      expect(group, equals(1));
      // recover previous state:
      await db.updateOne('update users set group_id=? where user_id=?;',
          params: [2, 2]);
    });
    test('updateOne-fail-zero', () async {
      try {
        await db.updateOne('update users set group_id=? where user_id=?;',
            params: [1, 0], throwOnError: true);
        expect(false, isTrue);
      } on DbException catch (exc) {
        expect(exc.toString(), contains('affected rows: 0 instead of 1'));
      }
      expect(
          await db.insertOne('update users set group_id=? where user_id=?;',
              params: [1, 0]),
          equals(0));
    });
    test('updateOrInsert', () async {
      await db.updateOrInsert('clouds', {
        'cloud_host': 1,
        'cloud_name': 'dragon',
        'cloud_total': 1000,
        'cloud_used': 100,
        'cloud_free': 900
      }, [
        'cloud_host',
        'cloud_name'
      ]);
      var count = await (countOfCloudName(db, 'dragon'));
      expect(count, equals(1));
      await db.updateOrInsert('clouds', {
        'cloud_host': 1,
        'cloud_name': 'dragon',
        'cloud_total': 1000,
        'cloud_used': 200,
        'cloud_free': 800
      }, [
        'cloud_host',
        'cloud_name'
      ]);
      count = await (countOfCloudName(db, 'dragon'));
      expect(count, equals(1));
      final used = await db.readOneInt(
          'select cloud_used from clouds where cloud_name=?',
          params: ['dragon']);
      expect(used, equals(200));
    });
    test('updateRaw-fail-SQL', () async {
      try {
        await db.updateOne('update clouds a=b;', throwOnError: true);
        expect(false, isTrue);
      } on DbException catch (exc) {
        expect(exc.toString(), contains(SQL_ERROR));
      }
      expect(await db.updateOne('update clouds a=b;'), isFalse);
    });
    test('deleteRaw-fail-SQL', () async {
      try {
        await db.deleteRaw('delete clouds a=b;');
        expect(true, isTrue);
      } on DbException catch (exc) {
        expect(exc.toString(), contains(SQL_ERROR));
      }
    });
  });
  group('readX', () {
    test('readAll-fail-SQL', () async {
      try {
        await db.readAll('select from users u;',
            params: ['<superflous>'], throwOnError: true);
        expect(false, isTrue);
      } on DbException catch (exc) {
        expect(exc.toString(), contains(SQL_ERROR));
      }
      expect(await db.readAll('select from users u;', params: ['<superflous>']),
          isNull);
    });
    test('readAllAsRecordLists', () async {
      final records = await db.readAllAsLists(
          'select user_id, user_name from users where user_id<? order by user_id;',
          params: [3]);
      expect(records, isNotNull);
      expect(
          records,
          equals([
            [1, 'adam'],
            [2, 'eve']
          ]));
    });
    test('readAllAsLists', () async {
      final records = await db.readAllAsLists(
          'select user_id, user_name from users where user_id<? order by user_id;',
          params: [3]);
      expect(
          records,
          equals([
            [1, 'adam'],
            [2, 'eve']
          ]));
    });
    test('readAllAsRecordMaps', () async {
      final records = await db.readAllAsMaps('''select u.*, g.* from users u
          left join groups g on g.group_id=u.group_id 
          where group_name='user';
          ''');
      expect(records, isNotNull);
      expect(records.length, greaterThanOrEqualTo(2));
      expect(records[0]['user_id'], equals(2));
      expect(records[0]['group_id'], equals(2));
      expect(records[0]['user_name'], equals('eve'));
      expect(records[0]['group_name'], equals('user'));

      expect(records[1]['user_id'], equals(3));
      expect(records[1]['group_id'], equals(2));
      expect(records[1]['user_name'], equals('david'));
      expect(records[1]['group_name'], equals('user'));
    });
    test('readOneAsMap', () async {
      final record = await db.readOneAsMap('''select user_id, user_name 
          from users where user_id=? order by user_id;''', params: [1]);
      expect(record, {'user_id': 1, 'user_name': 'adam'});
    });
    test('readOneAsMap-fail-zero', () async {
      try {
        await db.readOneAsMap('''select user_id, user_name 
          from users where user_id=? order by user_id;''',
            params: [0], throwOnError: true);
        expect(false, isTrue);
      } on DbException catch (exc) {
        expect(exc.toString(), contains('no record'));
      }
      expect(await db.readOneAsMap('''select user_id, user_name 
          from users where user_id=? order by user_id;''', params: [0]),
          isNull);
    });
    test('readOneAsMap-fail-more', () {
      expect(
          () async => await db.readOneAsMap('''select user_id, user_name 
          from users where user_id<? order by user_id;''',
              params: [3], throwOnError: true),
          throwsA(predicate(
              (e) => e is DbException && e.toString().contains('more than'))));
    });
    test('readOneInt', () async {
      final id = await db.readOneInt(
          'select user_id from users where user_id=?;',
          params: [1]);
      expect(id, equals(1));
    });
    test('readOneInt-null', () async {
      final id = await db.readOneInt(
          'select user_id from users where user_id=?;',
          nullAllowed: true,
          params: [0]);
      expect(id, isNull);
    });
    test('readOneInt-fail-not-int', () async {
      try {
        await await db.readOneInt('select created from users where user_id=?;',
            params: [1], throwOnError: true);
        expect(false, isTrue);
      } on DbException catch (exc) {
        expect(exc.toString(), contains('not an integer'));
      }
    });
    test('readOneInt-fail-zero', () async {
      try {
        await await db.readOneInt('select user_id from users where user_id=?;',
            params: [0], throwOnError: true);
        expect(false, isTrue);
      } on DbException catch (exc) {
        expect(exc.toString(), contains('no record'));
      }
      expect(
          await db.readOneInt('select user_id from users where user_id=?;',
              params: [0]),
          isNull);
    });
    test('readOneInt-fail-more', () async {
      try {
        await db.readOneInt('select user_id from users where user_id<?;',
            params: [3], throwOnError: true);
        expect(false, isTrue);
      } on DbException catch (exc) {
        expect(exc.toString(), contains('more than one record'));
      }
      final count =
          await db.readOneInt('select user_id from users where user_id<99;');
      expect(count, equals(1));
    });
    test('readOneString', () async {
      final name = await db.readOneString(
          'select user_name from users where user_id=?;',
          params: [1]);
      expect(name, equals('adam'));
    });
    test('readOneString-null', () async {
      final name = await db.readOneString(
          'select user_name from users where user_id=?;',
          params: [0],
          nullAllowed: true);
      expect(name, isNull);
    });
    test('readOneString-fail-zero', () async {
      try {
        await db.readOneString('select user_name from users where user_id=?;',
            params: [0], throwOnError: true);
        expect(false, isTrue);
      } on DbException catch (exc) {
        expect(exc.toString(), contains('no record'));
      }
      expect(
          await db.readOneString('select user_name from users where user_id=?;',
              params: [0]),
          isNull);
    });
    test('readOneString-fail-more', () async {
      try {
        await db.readOneString('select user_name from users where user_id<?;',
            params: [3], throwOnError: true);
        expect(false, isTrue);
      } on DbException catch (exc) {
        expect(exc.toString(), contains('more than one record'));
      }
    });
  });
  group('convert', () {
    test('convertNamedParams', () {
      final map = <String, dynamic>{':name': 'x', ':id': 22};
      final sqlAndList = MySqlDb.convertNamedParams(
          sql: "select * from users where :name='a' and :id < 9 or :name='b",
          mapParams: map,
          logger: logger);
      expect(sqlAndList, isNotNull);
      if (sqlAndList != null) {
        expect(sqlAndList.sql,
            equals("select * from users where ?='a' and ? < 9 or ?='b"));
        expect(sqlAndList.params.length, equals(3));
        expect(sqlAndList.params[0], equals('x'));
        expect(sqlAndList.params[1], equals(22));
        expect(sqlAndList.params[2], equals('x'));
      }
    });
    test('convertNamedParams-error', () {
      final map = <String, dynamic>{':name': 'x', ':idChanged': 22};
      logger.log('= expecting an error', 1);
      logger.errors.clear();
      final sqlAndList = MySqlDb.convertNamedParams(
          sql: "select * from users where :name='a' and :id < 9 or :name='b",
          mapParams: map,
          logger: logger);
      expect(sqlAndList, isNull);
      expect(logger.errors.length, equals(1));
      expect(
          logger.errors[0],
          equals(
              ":id not found in sql: select * from users where :name='a' and :id < 9 or :name='b"));
      MySqlDb.convertNamedParams(
          sql: "select * from users where :name='a' and :id < 9 or :name='b",
          mapParams: map,
          logger: logger,
          ignoreError: true);
      logger.contains('not found');
    });
  });
  group('callback', () {
    test('readAndExecute-global-function', () async {
      final sql = 'select * from groups where group_id > ?';
      final params = <String>['1'];
      lastRows = [];
      await db.readAndExecute(sql, params, doItWithOneRow);
      expect(lastRows.length, equals(1));
      expect(lastRows[0][1], equals('user'));
    });
    test('readAndExecute-class', () async {
      final tester = TestClass(db, logger);
      final rows = await tester.run();
      expect(rows.length, equals(1));
      expect(rows[0][1], equals('admin'));
    });
  });
  group('metadata', () {
    test('buildInsertFromResult', () async {
      await db.readAll('select * from users;');
      final sql = db.buildInsertFromResult('users', db.lastResults);
      expect(
          sql,
          equals(
              'insert into users(user_id,group_id,user_name,created,user_info) values (?,?,?,?,?);'));
    });
    test('buildInsertFromResult-excluded', () async {
      final sql = db.buildInsertFromResult('users', db.lastResults,
          excluded: ['user_id', 'created']);
      expect(
          sql,
          equals(
              'insert into users(group_id,user_name,user_info) values (?,?,?);'));
    });
    test('getTables', () async {
      final tables = await db.getTables();
      expect(tables, isNotNull);
      expect(tables, isNotEmpty);
    });
    test('hasTable', () async {
      expect(await db.hasTable('groups'), isTrue);
      expect(await db.hasTable('groups.not.known', forceUpdate: true), isFalse);
    });
    test('getColumns', () async {
      logger.clear();
      final columns = await db.getColumns('users');
      expect(columns, isNotNull);
      expect(columns.containsKey('user_id'), isTrue);
      final column = columns['user_id'];
      expect(column.name, equals('user_id'));
      expect(column.type, MysqlType.int);
      expect(column.typeName, 'int(10) unsigned');
      expect(column.size, 0);
      expect(column.options, 'primary notnull auto_increment');
      expect(column.defaultValue, 'null');
      expect(columns['user_name'].size, 200);
      expect(columns['user_name'].typeName, 'varchar(200)');
      expect(columns['created'].typeName, 'datetime');
      expect(columns['created'].options, ' null');
      expect(columns['created'].defaultValue, 'current_timestamp()');
      expect(columns['user_info'].size, 65535);
    });
  });
  group('trace', () {
    test('sql-trace-limit', () async {
      logger.clear();
      await db.readAll('select * from users WHERE users.user_name != '
          "'123456789 123456789 123456789 123456789 123456789 123456789 "
          "123456789 123456789 123456789 123456789 123456789 123456789 '");
      expect(logger.contains('sql: select * from users ..'), isTrue);
      expect(
          logger.contains(
              "WHERE users.user_name != '123456789 123456789 123456789 123456789 123456789 123456789 123456789..."),
          isTrue);
    });
    test('sql-trace-limit-lowercase', () async {
      logger.clear();
      await db.readAll('select * from users where users.user_name != '
          "'123456789 123456789 123456789 123456789 123456789 123456789 "
          "123456789 123456789 123456789 123456789 123456789 123456789 '");
      expect(logger.contains('sql: select * from users ..'), isTrue);
      expect(
          logger.contains(
              "where users.user_name != '123456789 123456789 123456789 123456789 123456789 123456789 123456789..."),
          isTrue);
    });
  });
  group('fixes', () {
    test('readOneString-missing record', () async {
      logger.clear();
      final result = await db
          .readOneString("select * from users where users.user_name 'xxx'");
      expect(result, isNull);
    });
  });
  group('executeScript-errors', () {
    test('wrong sql syntax', () async {
      db.throwOnError = true;
      logger.clear();
      db.currentScriptName = 'test-script';
      final result = await db.executeScript('''selllect from x;
'''
          .split('\n'));
      expect(result, '''+++ test-script-1: execute()
Error 1064 (42000): You have an error in your SQL syntax; check the manual that corresponds to your MariaDB server version for the right syntax to use near 'selllect from x' at line 1
selllect from x;
+++ script stopped on error: test-script-1
''');
      expect(logger.contains("near 'selllect"), isTrue);
    });
    test('wrong command', () async {
      logger.clear();
      db.currentScriptName = 'test-script';
      final result =
          await db.executeScript('''-- ! iff no records in select * from users
'''
              .split('\n'));
      expect(result,
          '''+++ test-script-1: unknown control statement: -- ! iff no records in select * from users
+++ script stopped on error: test-script-1
''');
      expect(logger.contains('unknown control statement'), isTrue);
    });
  });
  group('executeScript', () {
    test('if no records, empty then, else relevant', () async {
      logger.clear();
      db.currentScriptName = 'test-script';
      final result =
          await db.executeScript('''-- ! if no records in select * from users
-- ! else
-- ! say records found
-- ! endif
'''
              .split('\n'));
      expect(result, '''records found
''');
      expect(logger.errors.isEmpty, isTrue);
    });
    test('if missing column, else is relevant', () async {
      logger.clear();
      db.currentScriptName = 'test-script';
      final result =
          await db.executeScript('''-- ! if missing column users.user_id
-- ! say Error!
-- ! else
-- ! say column found
-- ! endif
'''
              .split('\n'));
      expect(result, '''column found
''');
      expect(logger.errors.isEmpty, isTrue);
    });
    test('if missing table, then is relevant, no else', () async {
      logger.clear();
      db.currentScriptName = 'test-script';
      final result = await db.executeScript('''-- ! if missing table DonaldDuck
-- ! say please create
-- ! endif
'''
          .split('\n'));
      expect(result, '''please create
''');
      expect(logger.errors.isEmpty, isTrue);
    });
    test('if missing table, then is relevant', () async {
      logger.clear();
      db.currentScriptName = 'test-script';
      final result = await db.executeScript('''-- ! if missing table DonaldDuck
-- ! say please create
-- ! else
-- say error!
-- ! endif
'''
          .split('\n'));
      expect(result, '''please create
''');
      expect(logger.errors.isEmpty, isTrue);
    });
    test('comment, say, select', () async {
      logger.clear();
      final result = await db.executeScript('''-- comment
-- ! say === count users
select count(*) from users;
-- ! say === count groups
select count(*) 
from groups;
'''
          .split('\n'));
      expect(result, '''=== count users
= count(*)
9
=== count groups
= count(*)
2
''');
      expect(logger.errors.isEmpty, isTrue);
    });
  });
  group('executeScriptFile', () {
    test('simple script', () async {
      db.throwOnError = true;
      logger.clear();
      final fn = path.join(fileSync.tempDirectory('unittest'), 'script.sql');
      fileSync.toFile(fn, '-- ! say Hi\n-- ! say World');
      final result = await db.executeScriptFile(fn);
      expect(result, '''Hi
World
''');
      expect(logger.errors.isEmpty, isTrue);
    });
    test('missing file', () async {
      db.throwOnError = true;
      logger.clear();
      final fn = 'notExistingScript.sql';
      final result = await db.executeScriptFile(fn);
      expect(
          result,
          '+++ FileSystemException: Cannot open file, path = '
          "'notExistingScript.sql'"
          ' (OS Error: No such file or directory, errno = 2)');
      expect(logger.errors.isNotEmpty, isTrue);
    });
  });
}

Future<int?> countOfCloudName(MySqlDb db, String name) async {
  final count = await db.readOneInt(
      'select count(*) from clouds where cloud_name=?',
      params: [name]);
  return count;
}

Future<int?> countOfUserId(MySqlDb db, int id) async {
  final count = await db.readOneInt(
      'select count(user_id) from users where user_id=?',
      params: [id]);
  return count;
}

List<dynamic> lastRows = [];

Future<bool> doItWithOneRow(List<dynamic> row) async {
  final rc = true;
  lastRows.add(row);
  return rc;
}

class TestClass {
  final MySqlDb _db;
  final _list = [];
  final BaseLogger _logger;

  TestClass(this._db, this._logger);

  Future<List<dynamic>> run() async {
    final sql = 'select * from groups where group_id < ?;';
    final parameters = <dynamic>[2];
    await _db.readAndExecute(sql, parameters, _doItWithOneRow);
    return _list;
  }

  Future<bool> _doItWithOneRow(List<dynamic> row) async {
    var rc = Future<bool>(() => false);
    _logger.log('found: ${row[0]}');
    _list.add(row);
    return rc;
  }
}
