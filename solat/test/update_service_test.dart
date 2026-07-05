import 'package:flutter_test/flutter_test.dart';
import 'package:solat/service/update_service.dart';

void main() {
  group('UpdateService Version Comparison Tests', () {
    test('should return true when remote version is higher (major)', () {
      expect(UpdateService.isNewerVersion('2.0.0', '1.0.0'), isTrue);
    });

    test('should return true when remote version is higher (minor)', () {
      expect(UpdateService.isNewerVersion('1.1.0', '1.0.0'), isTrue);
    });

    test('should return true when remote version is higher (patch)', () {
      expect(UpdateService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
    });

    test('should return false when versions are identical', () {
      expect(UpdateService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
    });

    test('should return false when remote version is lower', () {
      expect(UpdateService.isNewerVersion('0.9.0', '1.0.0'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.0', '1.0.1'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.0', '1.1.0'), isFalse);
    });

    test('should handle varying format lengths correctly', () {
      expect(UpdateService.isNewerVersion('1.0.0.1', '1.0.0'), isTrue);
      expect(UpdateService.isNewerVersion('1.0', '1.0.0'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.1', '1.0'), isTrue);
    });

    test('should handle malformed version segments gracefully by treating them as 0', () {
      expect(UpdateService.isNewerVersion('1.a.3', '1.0.2'), isTrue);
      expect(UpdateService.isNewerVersion('1.0.2', '1.a.2'), isFalse);
    });
  });
}
