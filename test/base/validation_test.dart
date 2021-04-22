import 'package:dart_bones/dart_bones.dart';
import 'package:test/test.dart';

void main() {
  group('real world types', () {
    test('isPhoneNumber', () {
      expect((Validation.isPhoneNumber('089-1234567')), isTrue);
      expect((Validation.isPhoneNumber('+49-89-1234567')), isTrue);
      expect((Validation.isPhoneNumber('+49-89-12 34 567')), isTrue);
      expect((Validation.isPhoneNumber('0891234567')), isTrue);
      expect((Validation.isPhoneNumber('+089+1234567')), isFalse);
      expect((Validation.isPhoneNumber('0 bock')), isFalse);
      expect((Validation.isPhoneNumber('')), isFalse);
    });
    test('isEmail', () {
      expect((Validation.isEmail('jonny@example.com')), isTrue);
      expect(
          true,
          equals(Validation.isEmail(
              'abcdefghijklmnopqrstuvwxyz@sv-0.example.com')));
      expect(
          true,
          equals(Validation.isEmail(
              'ABCDEFGHIJKLMNOPQRSTUVWXYZ@SV-0.EXAMPLE.COM')));
      expect(
          (Validation.isEmail(
              r'0123456789.!#$%&*+/=?^_`{|}~-@SV-0.EXAMPLE.COM')),
          isTrue);
      expect((Validation.isEmail('@SV-0.EXAMPLE.COM')), isFalse);
      expect((Validation.isEmail('@example.com')), isFalse);
      expect((Validation.isEmail('<>@example.com')), isFalse);
      expect((Validation.isEmail('')), isFalse);
    });
  });
  group('data types', () {
    test('isBool', () {
      expect((Validation.isBool('True')), isTrue);
      expect((Validation.isBool('true')), isTrue);
      expect((Validation.isBool('False')), isTrue);
      expect((Validation.isBool('yes')), isTrue);
      expect((Validation.isBool('NO')), isTrue);
      expect((Validation.isBool('t')), isTrue);
      expect((Validation.isBool('F')), isTrue);
      expect((Validation.isBool('wrong')), isFalse);
      expect((Validation.isBool('')), isFalse);
    });
  });
  group('numbers', () {
    test('isNat', () {
      expect(Validation.isNat('0'), isTrue);
      expect(Validation.isNat('1234567890'), isTrue);
      expect(Validation.isNat('0xabcdef01234567890'), isTrue);
      expect(Validation.isNat('0XABCDEF01234567890'), isTrue);
      expect(Validation.isNat('0o12345670'), isTrue);
      expect(Validation.isNat('0O12345670'), isTrue);
      expect(Validation.isNat('O'), isFalse);
      expect(Validation.isNat('a'), isFalse);
      expect(Validation.isNat('a0'), isFalse);
      expect(Validation.isNat('0a'), isFalse);
      expect(Validation.isNat('123456A7890'), isFalse);
      expect(Validation.isNat('xaffe01234567890'), isFalse);
      expect(Validation.isNat('0XAFFEG01234567890'), isFalse);
      expect(Validation.isNat('0o8'), isFalse);
      expect(Validation.isNat(''), isFalse);
    });
    test('isInt', () {
      expect(Validation.isInt('0'), isTrue);
      expect(Validation.isInt('1234567890'), isTrue);
      expect(Validation.isInt('-1234567890'), isTrue);
      expect(Validation.isInt('+1234567890'), isTrue);
      expect(Validation.isInt('0xabcdef01234567890'), isTrue);
      expect(Validation.isInt('0XABCDEF01234567890'), isTrue);
      expect(Validation.isInt('-0XABCDEF01234567890'), isTrue);
      expect(Validation.isInt('+0XABCDEF01234567890'), isTrue);
      expect(Validation.isInt('0o12345670'), isTrue);
      expect(Validation.isInt('-0o12345670'), isTrue);
      expect(Validation.isInt('+0o12345670'), isTrue);
      expect(Validation.isInt('0O12345670'), isTrue);
      expect(Validation.isInt('O'), isFalse);
      expect(Validation.isInt('a'), isFalse);
      expect(Validation.isInt('a0'), isFalse);
      expect(Validation.isInt('0a'), isFalse);
      expect(Validation.isInt('123456A7890'), isFalse);
      expect(Validation.isInt('xaffe01234567890'), isFalse);
      expect(Validation.isInt('0XAFFEG01234567890'), isFalse);
      expect(Validation.isInt('0o8'), isFalse);
      expect(Validation.isInt(''), isFalse);
    });
    test('isFloat', () {
      expect(Validation.isFloat('0'), isTrue);
      expect(Validation.isFloat('1234'), isTrue);
      expect(Validation.isFloat('-1234'), isTrue);
      expect(Validation.isFloat('+1234'), isTrue);
      expect(Validation.isFloat('1234.12'), isTrue);
      expect(Validation.isFloat('+1234.12'), isTrue);
      expect(Validation.isFloat('-1234.12'), isTrue);
      expect(Validation.isFloat('1234.12E+6'), isTrue);
      expect(Validation.isFloat('-1234.12E-6'), isTrue);
      expect(Validation.isFloat('12.7a'), isFalse);
      expect(Validation.isFloat('/12.7'), isFalse);
      expect(Validation.isFloat(''), isFalse);
    });
  });
}
