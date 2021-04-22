import 'package:dart_bones/dart_bones.dart';

/// The main function to demonstrate some features of dart_bones.
void main() async {
  showValidationAndStringUtils();
  showFileSync();
  showConfiguration();
  await showMysqlDb();
}

void showConfiguration() {
  // Configuration
  final logger = MemoryLogger();
  final map = <String, dynamic>{
    'db': {'name': 'dbtest', 'user': 'test', 'password': 'secret'},
    'level': 9,
  };
  final config = BaseConfiguration(map, logger);
  print(config.asInt('level'));
  print(config.asString('name', section: 'db', defaultValue: 'mysql'));
}

void showFileSync() {
  // FileSync:
  final fileSync = FileSync();
  final fn = fileSync.tempFile('test.data', subDirs: 'dir1/dir2');
  fileSync.toFile(fn, '1, 2');
  final content = fileSync.fileAsString(fn);
  assert(content == '1, 2');
  final content2 = fileSync.fileAsList(fn);
  assert(content2.length == 1 && content2[0] == '1, 2');
  // Remove and log errors:
  fileSync.ensureDoesNotExist(fn);

  print(fileSync.humanSize(123437829)); // "123.438MB"
}

Future<MySqlDb> showMysqlDb() async {
  final logger = MemoryLogger(LEVEL_DETAIL);
  final db = MySqlDb(
      dbName: 'testdb',
      dbUser: 'test',
      dbCode: 'TopSecret',
      dbHost: 'localhost',
      dbPort: 3306,
      logger: logger);
  var success;
  await db.connect();
  success = success && await db.execute('drop table if exists users;');
  success = success && await db.execute('''create table users(
  user_id int(10) unsigned NOT NULL AUTO_INCREMENT PRIMARY KEY,
  group_id int(10) unsigned,
  user_name varchar(200) NOT NULL,
  created datetime default now(),
  user_info text
  );
  ''');
  success = success && await db.execute('commit;');
  await db.insertRaw(
      "insert into users (user_id, user_name, group_id) values (1, 'adam', 1);");
  success = success && await db.execute('commit;');
  final countUsers = await db.readOneInt('select count(*) from users;');
  logger.log('count users: $countUsers', LEVEL_SUMMERY);
  return db;
}

void showValidationAndStringUtils() {
  // Validation and StringUtils:
  final value = '-0x7f3a';
  if (Validation.isNat(value) && Validation.isEmail('a@example.com') ||
      Validation.isPhoneNumber('+49-89-1234')) {
    print(asInt(value));
  }
  final answer = stringToEnum<Answer>('yes', Answer.values);
  print(enumToString(answer)); // "yes"
  print(limitString('A very long string ', 7, ellipsis: '..')); // "A very.."

  final text1 = 'Name: %name Year: %year';
  final text2 = replacePlaceholders(
      text1, {'name': 'joe', 'year': '2020'}, RegExp(r'%(\w+)'));
  print(text2); // "Name: joe Year: 2020"
}

enum Answer { yes, no }
