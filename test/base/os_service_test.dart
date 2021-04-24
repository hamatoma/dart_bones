import 'dart:io';

import 'package:dart_bones/src/base/base_logger.dart';
import 'package:dart_bones/src/base/os_service_io.dart';
import 'package:test/test.dart';

void main() {
  group('users/groups', () {
    test('user', () {
      final logger = BaseLogger(LEVEL_FINE);
      final service = OsService(logger);
      expect(service.userExists('bin'), isTrue);
      expect(service.userExists('bin_not_known'), isFalse);
      expect(service.groupExists('bin'), isTrue);
      expect(service.userId('root'), equals(0));
      expect(service.userId('bin'), equals(2));
    });
    test('group', () {
      final logger = BaseLogger(LEVEL_FINE);
      final service = OsService(logger);
      expect(service.groupExists('bin'), isTrue);
      expect(service.groupExists('bin_not_known'), isFalse);
      expect(service.groupId('root'), equals(0));
      expect(service.groupId('bin'), equals(2));
    });
  });
  group('UserInfo', () {
    test('basics', () {
      final info = UserInfo();
      expect(info.currentUserId, greaterThan(200));
      expect(info.currentUserName, isNotNull);
      expect(info.currentGroupName, isNotNull);
      expect(info.currentGroupId, greaterThan(200));
      expect(info.home, isNotNull);
      expect(Directory(info.home ?? '').existsSync(), isNotNull);
    });
  });
}
