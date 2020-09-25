import 'package:dart_bones/dart_bones.dart';
import 'package:test/test.dart';

void main() {
  group('String', () {
    test('isPhoneNumber', () {
      expect(true, equals(Validation.isPhoneNumber('089-1234567')));
      expect(true, equals(Validation.isPhoneNumber('+49-89-1234567')));
      expect(true, equals(Validation.isPhoneNumber('+49-89-12 34 567')));
      expect(true, equals(Validation.isPhoneNumber('0891234567')));
      expect(false, equals(Validation.isPhoneNumber('+089+1234567')));
      expect(false, equals(Validation.isPhoneNumber('0 bock')));
    });
    test('isEmail', () {
      expect(true, equals(Validation.isEmail('jonny@example.com')));
      expect(
          true,
          equals(Validation.isEmail(
              'abcdefghijklmnopqrstuvwxyz@sv-0.example.com')));
      expect(
          true,
          equals(Validation.isEmail(
              'ABCDEFGHIJKLMNOPQRSTUVWXYZ@SV-0.EXAMPLE.COM')));
      expect(
          true, equals(Validation.isEmail(r'0123456789.!#$%&*+/=?^_`{|}~-@SV-0.EXAMPLE.COM')));
      expect(false, equals(Validation.isEmail('@SV-0.EXAMPLE.COM')));
      expect(false, equals(Validation.isEmail('@example.com')));
      expect(false, equals(Validation.isEmail('<>@example.com')));
    });
  });
}
